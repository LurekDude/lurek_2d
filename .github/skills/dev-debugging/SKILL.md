---
name: dev-debugging
description: "Load this skill when diagnosing runtime bugs, crashes, or wrong behavior in Lurek2D. Skip it for feature work or test writing."
---
# dev-debugging

## Mission
- Own runtime diagnosis, repro building, and root-cause reporting.

## When To Load
- Investigate a crash.
- Investigate wrong runtime behavior.
- Read logs and traces.
- Build a small repro.

## When To Skip
- Feature implementation.
- Test authoring.

## Domain Knowledge
- Start from an existing failing script or fixture before reading src/. `tests/lua/`, `content/games/`, and `save/` already contain repro anchors. A narrowed Lua test or smoke case is faster to isolate than re-reading large module trees.
- Common failure surfaces in this repo, in order of frequency: `RefCell::borrow_mut()` panic inside a Lua callback (always check SharedState borrow scope), stale registry key after a scene reload, wrong callback ordering between `process` and `render`, RunState transition skipping an init step, and channel drop causing silent loss of a thread result.
- To trace a Lua-boundary crash: find the Lua call in logs (`RUST_LOG=lurek2d::lua_api=debug`), then find the corresponding `*_api.rs` binding, then trace from there into `src/<module>/`. Stop at the first concrete control path that explains the symptom.
- To trace a render glitch: find which `RenderCommand` variant is wrong or missing in the command buffer log (`RUST_LOG=lurek2d::render=trace`). Then find where that command is pushed. Never start by reading the shader unless the command itself is correct.
- Use `tools/audit/parse_test_log.py` for harness failures — it extracts structured pass/fail context from the Lua test harness output. Do not scroll raw cargo test output for Lua failures.
- Separate failure classes before forming hypotheses: crash (panic or SIGSEGV), wrong result (logic error), missing side effect (event never fired), stale state (old value persisted), race (non-deterministic), and backend-specific (wgpu validation layer error). Each implies a different first check.
- Build the smallest deterministic repro first: one Lua test, one content/games/ main.lua, or one Rust test that reliably reproduces. Write it under `work/{session}/scripts/` so it survives the session. A non-reproducible repro is not a repro.
- When a bug crosses the Lua boundary, compare `docs/specs/<module>.md` Lua API section against the binding in `src/lua_api/<module>_api.rs` first. Spec drift — where the doc says one thing and the binding does another — is a common root cause.
- For save-file or filesystem-triggered bugs, note the exact save path relative to the GameFS root, the triggering operation (`lurek.fs.read`, `lurek.save.load`, etc.), and the visible symptom before reading any src/ code.
- Confidence marking rule: CONFIRMED = demonstrated by a single test that fails and passes in controlled conditions. LIKELY = two independent signals point to the same cause. SUSPECT = one signal that could have other explanations. Never report CONFIRMED without a passing fix or reproducer.
- Check Clippy output (`cargo clippy --all-targets -- -D warnings`) after reproducing, because sometimes the root cause is a known pattern that Clippy would already flag.
## Companion File Index
- None.

## References
- logs/
- tests/
- src/
- tools/audit/parse_test_log.py
