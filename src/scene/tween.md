# tween — Animation Tweening System

> **Lua namespace:** `luna.tween`
> **C++ module:** `src/modules/tween/`
> **Purpose:** Provides a complete tweening (interpolation) system for animating numeric properties on Lua tables, with support for easing functions, sequences, parallel groups, repeat/yoyo, and lifecycle callbacks.

## Reimplementation Notes

- The tween system operates on **Lua tables** — you pass a target table and a fields table `{fieldName = endValue, ...}`. The tweener reads start values from the target table on first update, then writes interpolated values each frame.
- All active tweens are tracked globally by the `TweenModule`. `luna.tween.update(dt)` advances all registered tweens. Individual tweens auto-register on creation.
- Each Tween, TweenSequence, and TweenParallel stores Lua registry references (`luaL_ref`) for targets, callbacks, and custom easing functions. These are properly unref'd on destruction.
- Start values are captured lazily — on first `update()` call, not at creation time. This allows the target table to be modified between tween creation and first frame.
- Custom easings are registered globally via `registerEasing(name, fn)`. The easing function receives `(t)` where `t` is 0..1 and must return 0..1.
- 24 built-in easings: `linear`, `quadIn`, `quadOut`, `quadInOut`, `cubicIn`, `cubicOut`, `cubicInOut`, `quartIn`, `quartOut`, `sineIn`, `sineOut`, `sineInOut`, `expoIn`, `expoOut`, `expoInOut`, `circIn`, `circOut`, `elasticIn`, `elasticOut`, `backIn`, `backOut`, `bounceOut`, `bounceIn`.
- `TweenSequence` runs steps in order — each step can be a tween, a delay, or a callback. Steps run one at a time.
- `TweenParallel` runs multiple tweens simultaneously; completes when all finish.
- All `onComplete`, `onUpdate`, `onCancel` methods return `self` for chaining.

## Dependencies

- None (standalone module, operates on Lua tables via registry refs)

## Module Functions

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `update` | `update(dt)` | — | Advance all active tweens by `dt` seconds. Call once per frame. |
| `tween` | `tween(duration, target, fields [, easing])` | `Tween` | Create and register a tween. `target` is a Lua table, `fields` is `{name=endValue, ...}`, `easing` defaults to `"linear"`. |
| `sequence` | `sequence()` | `TweenSequence` | Create an empty tween sequence for chaining steps. |
| `parallel` | `parallel()` | `TweenParallel` | Create an empty parallel group for running tweens simultaneously. |
| `delay` | `delay(seconds [, callback])` | `Tween` | Create a no-op tween that waits `seconds`, then optionally calls `callback`. |
| `cancelAll` | `cancelAll()` | — | Cancel all active tweens, sequences, and parallel groups. |
| `registerEasing` | `registerEasing(name, fn)` | — | Register a custom easing function. `fn(t)` receives 0..1, returns 0..1. |
| `getEasingNames` | `getEasingNames()` | `table` | Get a list of all available easing names (built-in + custom). |
| `getActiveCount` | `getActiveCount()` | `int` | Get the number of currently active tweens. |

## Type: Tween

Represents a single property interpolation over time.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `cancel` | `cancel()` | — | Cancel this tween immediately. Fires `onCancel` callback if set. |
| `pause` | `pause()` | — | Pause this tween. It stops advancing but is not cancelled. |
| `resume` | `resume()` | — | Resume a paused tween. |
| `isActive` | `isActive()` | `boolean` | Returns true if the tween is still running (not completed/cancelled). |
| `getProgress` | `getProgress()` | `number` | Returns current progress as 0..1 (based on elapsed/duration). |
| `setRepeat` | `setRepeat(n)` | — | Set the number of times to repeat the tween after the first play. |
| `setYoyo` | `setYoyo(enabled)` | — | If true, the tween reverses direction on each repeat (ping-pong). |
| `onComplete` | `onComplete(fn)` | `Tween` | Set callback called when the tween finishes. Returns self for chaining. |
| `onUpdate` | `onUpdate(fn)` | `Tween` | Set callback called on each update tick. Returns self for chaining. |
| `onCancel` | `onCancel(fn)` | `Tween` | Set callback called when the tween is cancelled. Returns self for chaining. |

## Type: TweenSequence

Runs a series of steps (tweens, delays, callbacks) one after another in order.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `tween` | `tween(duration, target, fields [, easing])` | `TweenSequence` | Append a tween step. Same params as `luna.tween.tween()`. Returns self. |
| `delay` | `delay(seconds)` | `TweenSequence` | Append a delay step. Returns self. |
| `callback` | `callback(fn)` | `TweenSequence` | Append a callback step (called when reached). Returns self. |
| `start` | `start()` | — | Begin executing the sequence from the first step. |
| `cancel` | `cancel()` | — | Cancel the entire sequence. |
| `isActive` | `isActive()` | `boolean` | Returns true if the sequence is still running. |
| `onComplete` | `onComplete(fn)` | `TweenSequence` | Set callback for when all steps complete. Returns self. |

## Type: TweenParallel

Runs multiple tweens simultaneously. Completes when all child tweens finish.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `add` | `add(tween)` | — | Add a Tween to the parallel group. |
| `start` | `start()` | — | Begin executing all child tweens simultaneously. |
| `cancel` | `cancel()` | — | Cancel all child tweens. |
| `isActive` | `isActive()` | `boolean` | Returns true if any child tween is still running. |
| `onComplete` | `onComplete(fn)` | `TweenParallel` | Set callback for when all children complete. Returns self. |

## Built-in Easing Functions

| Category | In | Out | InOut |
|----------|----|-----|-------|
| Linear | `linear` | — | — |
| Quad | `quadIn` | `quadOut` | `quadInOut` |
| Cubic | `cubicIn` | `cubicOut` | `cubicInOut` |
| Quart | `quartIn` | `quartOut` | — |
| Sine | `sineIn` | `sineOut` | `sineInOut` |
| Expo | `expoIn` | `expoOut` | `expoInOut` |
| Circ | `circIn` | `circOut` | — |
| Elastic | `elasticIn` | `elasticOut` | — |
| Back | `backIn` | `backOut` | — |
| Bounce | `bounceIn` | `bounceOut` | — |

## Usage Examples

### Basic Tween

```lua
local obj = { x = 0, y = 0, alpha = 1 }

-- Move obj.x to 100 and obj.y to 200 over 2 seconds with ease-out
local t = luna.tween.tween(2.0, obj, { x = 100, y = 200 }, "cubicOut")
t:onComplete(function() print("done!") end)

function luna.update(dt)
    luna.tween.update(dt)
    -- obj.x and obj.y are updated automatically
end
```

### Sequence (Chained Animations)

```lua
local player = { x = 0, y = 0 }

luna.tween.sequence()
    :tween(1.0, player, { x = 100 }, "quadOut")
    :delay(0.5)
    :callback(function() print("halfway!") end)
    :tween(1.0, player, { y = 200 }, "bounceOut")
    :onComplete(function() print("full sequence done") end)
    :start()
```

### Parallel (Simultaneous Animations)

```lua
local t1 = luna.tween.tween(1.0, sprite, { x = 100 })
local t2 = luna.tween.tween(1.5, sprite, { alpha = 0 }, "expoOut")

local par = luna.tween.parallel()
par:add(t1)
par:add(t2)
par:onComplete(function() print("both done") end)
par:start()
```

### Repeat and Yoyo

```lua
local pulse = luna.tween.tween(0.5, light, { intensity = 2.0 }, "sineInOut")
pulse:setRepeat(5)   -- play 6 times total
pulse:setYoyo(true)  -- alternate direction each repeat
```

### Custom Easing

```lua
luna.tween.registerEasing("bounceCustom", function(t)
    return 1 - math.abs(math.sin(t * math.pi * 3)) * (1 - t)
end)

luna.tween.tween(2.0, obj, { scale = 2.0 }, "bounceCustom")
```

---

## Game Design Role

- **UI animation**: Slide menus in/out, fade buttons, pulse selection highlights.
- **Camera movement**: Smooth pan to targets, shake effects via yoyo tweens, zoom transitions.
- **Cutscenes**: Sequence character movements, object transforms, and timed callbacks without coroutine spaghetti.
- **Juiciness**: Add bounce, elastic, and overshoot easing to make interactions feel alive.
- **World objects**: Animate doors opening, platforms moving, lights flickering with repeat/yoyo.
- **Screen transitions**: Fade-to-black, wipe effects, and iris transitions between scenes.

---

## Module Boundaries

**vs luna.timer** — Timer provides raw `getDelta()` and `sleep()`. Tween uses `dt` from the game loop to advance interpolation. Timer measures time; Tween uses time to animate values.

**vs luna.graphics** — Graphics renders visuals. Tween modifies numeric fields (x, y, alpha, scale) on data tables; Graphics draws whatever those values say each frame.

**vs luna.ai (StateMachine)** — StateMachine handles discrete state transitions (idle → walk → attack). Tween handles *continuous* value interpolation within a state (smoothly moving x from 0 to 100).

**vs luna.gui** — GUI widget animations (slide-in, fade, highlight pulse) are driven by tweens. Create a tween targeting the widget's properties table.

---

## Edge Cases & Pitfalls

- **Non-numeric fields silently skipped**: If a target table has a field of type string or boolean, the tweener skips it without error. Only `number` values are interpolated. Verify field types before tweening.
- **Cancelled tweens keep last value**: Calling `cancel()` does NOT reset the target fields to their start values. The target retains whatever interpolated value it had at cancellation time. To "undo" a tween, create a reverse tween.
- **Overlapping tweens on same field**: If two tweens target the same field on the same table, the last one updated "wins" each frame — they overwrite each other. Cancel the first tween before starting the second, or use a sequence.
- **Zero-duration tween**: A tween with `duration = 0` completes instantly on the next `update()` call, jumping directly to the end values. The `onComplete` callback still fires.
- **Sequence completion**: A TweenSequence fires `onComplete` after the last step finishes. If a callback step in the middle errors, subsequent steps are skipped and `onComplete` does not fire.

---

## Planned / To Implement

- **Path tween**: Interpolate along a BezierCurve or polyline path instead of single start→end values.
- **Spring tween**: Physics-based spring interpolation with configurable stiffness and damping.
- **Easing preview**: Dev tool that renders all easing curves as interactive graphs for tuning.
- **Timeline JSON export**: Export a TweenSequence definition as JSON for external animation editors.
- **Pause / resume groups**: Pause and resume all tweens in a named group (e.g. pause UI tweens during gameplay, keep gameplay tweens running).
