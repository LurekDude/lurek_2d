# IDEA.md — `input` module

> Migrated from `ideas/features/input.md`.
> Status checked against `src/input/` and `src/lua_api/input_api.rs`.
> Lua namespaces: `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, `lurek.touch`.

---

## Features

### ✅ DONE — Custom Cursor
**Source**: features/input.md — Suggestions #4

`setCursor(image, hotX, hotY)` implemented in `input_api.rs` (line ~285). Sets cursor from
ImageData or system cursor name.

---

### ✅ DONE — Input Action Mapping (HIGH PRIORITY)
**Source**: features/input.md — Feature Gaps #1 / Suggestions #1

No `lurek.input.bind("jump", {"space", "gamepad:a"})` or `isActionDown("jump")` found.
This is the #1 missing input feature — every game re-implements key rebinding from scratch.

Suggested API:
```lua
lurek.input.bind("jump", {"space", "gamepad:a"})
lurek.input.isActionDown("jump")   -- true if any bound source is held
lurek.input.wasActionPressed("jump")
```

Consider implementing as a new `input_map` module or as a namespace within `lurek.input`.

---

### ✅ DONE — Input Buffering (Frame Tolerance)
**Source**: features/input.md — Feature Gaps #8 / Suggestions #5

No `wasActionPressedWithin("jump", frames)` found. Frame-tolerance input is essential for
responsive platformer controls (coyote time, jump queueing).

---

### ❌ TODO — Input Recording / Playback
**Source**: features/input.md — Feature Gaps #3 / Suggestions #2

No `startRecording()` / `stopRecording()` / `playback(log)` found. Input recording is
foundational for deterministic testing, replays, and speedrun tooling.

Note: the `automation` module (`lurek.simulator`) handles scripted input — document whether
recording bridges the two or is fully separate.

---

### ❌ TODO — Gamepad Vibration (Haptics)
**Source**: features/input.md — Feature Gaps #6 / Suggestions #3

No `lurek.gamepad.vibrate(pad, low, high, duration)` found. Requires winit haptics API
support (may need to check winit 0.30 capabilities).

---

### ❌ TODO — Combo / Sequence Detection
**Source**: features/input.md — Feature Gaps #2

No combo detection (e.g., fighting game inputs `↓↘→ + A`). Implement as a helper in the
`automation` module or as a sub-namespace `lurek.input_combo`.

---

### ✅ DONE — Unified `lurek.input` Facade
**Source**: features/input.md — Structural Issues

Four separate namespaces (`keyboard`, `mouse`, `gamepad`, `touch`) are clear but verbose.
Consider also exposing `lurek.input` as a unified query interface — device-agnostic for
action mapping. This is additive, not a breaking change.
