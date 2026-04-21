# IDEA.md — `automation` module

| Field       | Value             |
| ----------- | ----------------- |
| Module      | `automation`      |
| Path        | `src/automation/` |
| Date        | 2026-04-18        |
| Plugin Tier | TIER-1-PLUGIN     |

---

## Mission Summary

Record, replay, and script deterministic input sequences for automated game
testing. Provides `Script` (TOML-defined step list), `Step` (single input event),
and `Simulator` (playback engine with play/pause/stop/record/macro management).
Lua namespace: `lurek.automation`.

## Existing Strengths

- 8 action types covering full input surface: key press/release, mouse
  press/release/move, wheel, text input, wait.
- TOML-driven scripts with optional metadata (description, step limit).
- Macro recording: capture ad-hoc step sequences and replay named macros.
- Playback speed control (slow-mo for debugging, fast-forward for CI).
- Clean action parse/as_str roundtrip for serialization.
- Simulator state machine: idle → playing → paused → resumed → stopped.
- Step `effective_scancode()` fallback: scancode → key → None.

## Gap List

1. No screenshot comparison / visual assertions — cannot do pixel-level
   regression testing without `image` module integration.
2. No loop/repeat construct in scripts — must duplicate steps for repetitive
   input.
3. No conditional steps (e.g. "press A only if HP < 50") — fully linear.
4. `Simulator::update` couples directly to `EventQueue` — hard to unit test
   the event emission path without a full event system.
5. No delta-time determinism guarantee — playback speed * dt can accumulate
   float drift over long scripts.

## Feature Ideas

1. **Visual Assertion Steps** — Integrate with `image` module to capture and
   compare screenshots at scripted points. Selenium's visual-regression and
   Playwright's `toHaveScreenshot()` are references.
2. **Script Looping / Subroutines** — Add `loop`, `call_macro`, and `repeat`
   actions to reduce duplication. AutoHotkey's `Loop` construct is a reference.
3. **Conditional Steps / Assertions** — Allow steps gated on Lua expressions
   (e.g. `assert: "hp > 0"`). Robot Framework's `Run Keyword If` is a
   reference.

## Perf/Quality Ideas

- Benchmark playback of 10 000-step scripts to confirm sub-ms overhead per
  `update()` call.
- Profile `from_toml` parsing for large TOML scripts (1 000+ steps).

## Test Coverage Gaps

- Tests added this session: step.rs (parse, roundtrip, effective_scancode),
  script.rs (new, description, duration, from_toml valid/invalid),
  simulator.rs (state transitions, macro record/list/delete, playback speed).
- Missing: `Simulator::update()` event emission (requires EventQueue mock or
  extraction of the event-building logic).
- Missing: `from_toml` with all step field combinations (x, y, button, etc.).

## TODO(dedup): automation ↔ timer scheduling

- `Simulator` tracks elapsed time with `f32` accumulation. The `timer` module
  has `TimeAccumulator` for the same purpose — consider sharing.

## TODO(dedup): automation ↔ input events

- `Step` action names ("keypressed", "mousemoved") duplicate `input` module
  event name strings. Consider a shared `InputEventKind` enum.

## TODO(helper):

- `Action::parse_action` / `Action::as_str` mapping table is duplicated in two
  match arms — extract a `const` array of `(&str, Action)` pairs.

## TODO(plugin):

- Automation is a TIER-1-PLUGIN candidate — useful for testing but not required
  for game runtime. Gate behind a Cargo feature flag.

## References

- `docs/specs/automation.md`
- `src/lua_api/automation_api.rs`
- Playwright visual comparison: https://playwright.dev/docs/test-snapshots
- AutoHotkey Loop: https://www.autohotkey.com/docs/v2/lib/Loop.htm
