# input — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/input.md`
**Files**: Keyboard, mouse, gamepad, touch state polling

## Purpose

Input state management: detect pressed/released keys, mouse position/buttons, gamepad axes/buttons, touch points. Stateless polling model — no callbacks.

## Current Feature Summary

- 4 input namespaces: `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, `lurek.touch`
- Key state: `isDown(key)`, `wasPressed(key)`, `wasReleased(key)` — per-frame edge detection
- Mouse: position, buttons, wheel delta, relative motion
- Gamepad: up to 4 pads, axes with deadzone, buttons, triggers
- Touch: multi-touch points with position and ID tracking
- Scancode and key name mapping
- Text input events via `lurek.textInput` callback
- Cursor visibility and lock

## Feature Gaps

1. **No input action mapping**: No way to bind game actions to keys/buttons. Every game reimplements "jump = space or gamepad A" from scratch. This is the #1 missing input feature.
2. **No combo/sequence detection**: No built-in pattern detection for fighting game inputs, cheat codes, or gesture combos.
3. **No input recording/playback**: Cannot record input streams for replays, testing, or debugging.
4. **No gesture recognition**: No swipe, pinch, or long-press detection (even for mouse — drag detection is manual).
5. **No IME support**: Text input via `lurek.textInput` callback works for ASCII but complex input methods (CJK, accented characters) may not be handled.
6. **No vibration/haptics**: Gamepad rumble is not exposed.
7. **No mouse cursor customization**: Can show/hide cursor but can't set custom cursor images.
8. **No input buffering**: No built-in frame-tolerance for input timing (common in platformers — "press jump within 5 frames of landing").

## Structural Issues

- **Clean scope**: Input is correctly positioned as a Tier 1 polling module. No structural issues.
- **Four namespaces vs one**: Having `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, `lurek.touch` as separate namespaces is clear but verbose. Consider also exposing `lurek.input` as a unified query facade.

## Suggestions

1. **Add input action mapping** (high priority): `lurek.input.bind("jump", {"space", "gamepad:a"})` → `lurek.input.isActionDown("jump")`. This is the single most impactful missing input feature. Every competitor either has it built-in or it's the first thing users build.
2. **Add input recording**: `lurek.input.startRecording()` / `lurek.input.stopRecording()` → returns a replayable input log. Transforms testing and replay systems.
3. **Add gamepad vibration**: `lurek.gamepad.vibrate(pad, low, high, duration)` — requires winit vibration API.
4. **Add custom cursor**: `lurek.mouse.setCursor(image, hotX, hotY)` — set cursor from ImageData or system cursor name.
5. **Add input buffer**: `lurek.input.wasActionPressedWithin("jump", frames)` — returns true if action was pressed within N frames. Essential for responsive platformer controls.

## Competitor Comparison

| Feature | Lurek2D | Engine A | Engine B | Engine D |
|---|---|---|---|---|
| Key polling | ✅ | ✅ | ✅ (events) | ✅ |
| Gamepad | ✅ | ✅ | ❌ | ✅ |
| Touch | ✅ | ✅ | ✅ | ✅ |
| Action mapping | ❌ | ❌ | ❌ | ✅ (leafwing) |
| Input recording | ❌ | ❌ | ❌ | ❌ |
| Vibration | ❌ | ✅ | ❌ | ✅ |
| Gestures | ❌ | ❌ | ✅ | ❌ |
| Custom cursor | ❌ | ✅ | ✅ | ✅ |

## Priority

**HIGH** — Input action mapping is a critical missing feature. Most games need key rebinding and input abstraction. This could be a new `input_map` module or integrated into `input`.
