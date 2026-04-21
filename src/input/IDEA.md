# IDEA — `src/input/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.

---

## 1. Header

- **Module**: `input`
- **Owner module path**: `src/input/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~1700 · **Public Lua surface**: `lurek.input.keyboard`, `lurek.input.mouse`, `lurek.input.gamepad`, `lurek.input.touch` — ~45 fns / 0 userdata
- **Inbound non-`lua_api` callers**: `app` (event dispatch), `runtime` (state init)
- **Heavy dependencies**: `gilrs` (gamepad)

## 2. Mission Summary

Translates raw platform input events into game-consumable state. Serves EngDev (event
integration), GameDev (keyboard/mouse/gamepad/touch queries from Lua), and GameTest (input
recording/playback for automated testing). Deliberately NOT an action-mapping system —
provides raw device state, not semantic "jump"/"fire" mappings.

## 3. Existing Strengths

- Clean device separation: keyboard, mouse, gamepad, and touch each in own file with own state struct.
- Combo detection system (`combo.rs`) supports multi-step key sequences with configurable timeouts.
- Input recording/playback (`recorder.rs`) with JSON serialization for automated test replay.
- Gamepad hat-direction synthesis from D-pad buttons — correct 8-direction logic.
- Winit ↔ engine key mapping with comprehensive coverage of standard and special keys.
- Mouse cursor management with system cursor presets and custom image cursor support.

## 4. Gap List

1. **[P2][GAP]** `Action mapping layer` — no semantic input bindings ("jump" → Space or gamepad A).
   - Why: every game reimplements key→action mapping in Lua; could be a standard library.
2. **[P2][GAP]** `Gamepad rumble/vibration` — no force-feedback API.
   - Why: gamepad games expect haptic feedback; gilrs supports it.
3. **[P3][GAP]** `Input buffering / frame-perfect detection` — `isDown` is polled; no pressed-this-frame vs held distinction in touch/gamepad.
   - Why: fighting games and platformers need frame-accurate input timing.

## 5. Feature Ideas

1. **[P2][FEAT]** `lurek.input.newMapping(name, bindings)` — Action mapping helper.
   - Rationale: standard pattern that every game needs; reduces boilerplate.
   - Effort: M · Risk: low (pure Lua library candidate under `content/library/`).
   - Competitor inspiration: [Godot: InputMap — docs.godotengine.org/en/stable/classes/class_inputmap.html].
2. **[P2][FEAT]** `lurek.input.gamepad.setVibration(id, left, right, duration)` — Rumble support.
   - Rationale: haptic feedback is expected in modern gamepad games.
   - Effort: S · Risk: low (gilrs has `set_ff_state`).
   - Competitor inspiration: [LOVE2D: love.joystick.setVibration — love2d.org/wiki/Joystick:setVibration].
3. **[P3][FEAT]** `Multi-gamepad hot-plug tracking` — automatic connect/disconnect events via Lua callbacks.
   - Rationale: couch co-op games need dynamic player join/leave.
   - Effort: M · Risk: med (gilrs event pump integration with winit loop).

## 6. Performance / Reliability / Quality Ideas

- **[P3][QUAL]** `Combo detector timeout units` — timeout is `f64` with no documented unit; should be explicit ms or use Duration.
  - File: `combo.rs:30`.
  - Reason: prevents silent bugs when GameDev passes seconds instead of milliseconds.
- **[P3][QUAL]** `Recorder JSON schema versioning` — JSON format has no version field; schema changes break old recordings.
  - File: `recorder.rs`.
  - Reason: add `"version": 1` to serialized recordings for forward compat.
- **[P3][PERF]** `Keyboard scancode map initialization` — rebuilds HashMap on every `clear_frame`; could keep and clear.
  - Hot path: `keyboard.rs:180-200`.
  - Verification: profile with 1000 frames of heavy key input.

## 7. Test Coverage Gaps

- **[P1][TEST-RUST]** Add Rust unit test for `gamepad::GamepadState` button/axis/hat operations (now added).
- **[P1][TEST-RUST]** Add Rust unit test for `recorder::InputRecorder` recording/playback cycle (now added).
- **[P2][TEST-LUA]** Add Lua BDD test for `lurek.input.keyboard.isDown`, `lurek.input.mouse.getPosition` under `tests/lua/input/`.
- **[P2][TEST-RUST]** Add Rust unit test for `gamepad::GamepadMappings` string parsing.
- **[P3][TEST-FUZZ]** Fuzz target candidate: `gamepad::GamepadMappings::load_from_string` with malformed SDL mapping strings.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): event::EventSystem — event module has input-event dispatch that overlaps with recorder's event capture
TODO(dedup): window::management — cursor show/hide lives in both window and mouse modules
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): input_action_map — action→key binding pattern repeated in every game script — citation: content/library/input/init.lua:1
TODO(helper): virtual_dpad — touch-screen D-pad emulation repeated in mobile-style games — citation: content/examples/touch.lua:1
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): CORE-KEEP — input is fundamental to every interactive game; no game runs without input handling.
```

- **Extraction blockers**: `app` event loop dispatches directly to input state; `runtime::shared_state` holds all input structs.
- **Heavy dep impact if extracted**: `gilrs` crate (~1.2 MB compiled) only used by gamepad.
- **Lua surface stability**: stable.
- **Migration step**: n/a (CORE-KEEP).

## 11. References

- Module spec: [docs/specs/input.md](../../../docs/specs/input.md)
- Lua API reference: [docs/API/lua-api.md#keyboard](../../../docs/API/lua-api.md)
- Philosophy constraints touched: `A-02` (desktop only — no mobile touch primary), `B-04` (no cross-VM state for input)
- Plugin doc tier table: [plugins.md §5](../../../docs/architecture/plugins.md#5-candidate-modules)
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
