# automation — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/automation.md`
**Files**: Simulated input for testing and bots

## Purpose

Programmatic input simulation: inject keyboard, mouse, gamepad, and touch events for automated testing, replays, tutorials, and AI-driven characters.

## Current Feature Summary

- Simulated keyboard: press, release, type text
- Simulated mouse: move, click, scroll, drag
- Simulated gamepad: button press, axis movement
- Simulated touch: touch/move/release points
- Input recording: capture real input for replay
- Input playback: replay recorded input sequences
- Frame-accurate timing (synchronized with game loop)
- Queue-based: inputs queued and applied at start of next frame

## Feature Gaps

1. **No visual test assertions**: Can simulate input but can't assert on visual output (screen comparisons, pixel checks). Needs `saveScreenshot()` integration.
2. **No wait-for-condition**: Can queue inputs but can't say "wait until entity X reaches position Y, then press space." Must use frame counting.
3. **No named macros**: Can't save named input sequences for reuse ("open_inventory", "attack_combo").
4. **No slow-motion playback**: Replay at configurable speed for debugging.
5. **No integration with entity module**: Can't simulate input relative to game entities (e.g., "click on enemy" requires manual coordinate calculation).

## Structural Issues

- **Good scope**: Automating input simulation is a distinct, well-bounded concern.
- **Tier 1 seems right**: Testing automation is core infrastructure.
- **Block-pattern in lua_api**: `automation_api.rs` uses the `{ }` block wrapper pattern for registrations. Should be converted to flat body pattern.

## Suggestions

1. **Add named macros**: `luna.automation.saveMacro("combo", sequence)` / `luna.automation.playMacro("combo")` — reusable input scripts.
2. **Add wait-for-condition**: `luna.automation.waitUntil(predicate, timeout)` — blocks automation queue until condition met.
3. **Add screenshot comparison**: Integration with `saveScreenshot()` + `image` module for visual regression testing.
4. **Add variable speed playback**: `luna.automation.setPlaybackSpeed(factor)` — slow down or speed up replay.
5. **Add highlight mode**: During replay, show visual indicators of simulated inputs (cursor position, key presses) for debugging.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Input simulation | ✅ | ❌ | ❌ | ❌ |
| Input recording | ✅ | ❌ | ❌ | ❌ |
| Input replay | ✅ | ❌ | ❌ | ❌ |
| Visual testing | ❌ | ❌ | ❌ | ❌ |

Luna2D is unique in having built-in automation. This is a genuine differentiator. Polish it.

## Priority

**MEDIUM** — The automation module is already distinctive. Named macros and wait-for-condition would make it production-ready for automated testing pipelines.
