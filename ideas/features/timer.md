# timer — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/timer.md`
**Files**: Clock + Scheduler

## Purpose

Time management: delta time, FPS tracking, time scaling, named scheduled events (after/every).

## Current Feature Summary

- `Clock`: tracks delta time, total elapsed, FPS, frame count
- `Scheduler`: named events with `after(delay, fn)` and `every(interval, fn)`
- Time scale: `luna.timer.setTimeScale(scale)` — slow-mo / fast-forward
- Performance timing: `luna.timer.performanceTiming(fn)` → microseconds
- Sleep: `luna.timer.sleep(seconds)` — blocking pause (development use)
- Named event management: cancel, list, check existence

## Feature Gaps

1. **No coroutine-based timing**: Can't write `wait(1.5)` inside a coroutine. Must use callbacks for all delayed operations. Coroutine-friendly timing is much more readable for sequential game logic.
2. **No delta time smoothing**: Original Luna2D C++ engine had this. Raw delta time can spike on hitches. Smoothed delta (running average) prevents "teleporting" entities.
3. **No fixed timestep**: No built-in accumulator for physics-rate updates. Must be implemented manually in Lua.
4. **No cron-like patterns**: Can do `every(seconds, fn)` but can't schedule "every 5th call" or "at time 10.0".
5. **No pause/resume for scheduled events**: Can cancel an event but can't pause/resume it.
6. **No timer chains**: Can't schedule "do A after 1s, then B after 2s, then C after 0.5s" as a single chain (must nest callbacks).
7. **No global pause integration**: `setTimeScale(0)` stops time but there's no "unpauseable" timer concept for UI animations during pause.

## Structural Issues

- **Clean module**: Small, focused, well-defined scope. No structural issues.
- **Tween ambiguity**: Timer handles `after/every` scheduling. Animation module handles frame-based animation. Math module has Tween type. Property animation over time (tween a value from A to B over N seconds) falls between all three. Should clarify which module owns "tween this number over time."

## Suggestions

1. **Add delta time smoothing**: `Config` option or `luna.timer.setSmoothingFactor(n)` — running average over N frames. Prevents jitter.
2. **Add coroutine wait support**: `luna.timer.waitFrames(n)` / `luna.timer.waitSeconds(t)` — yields current coroutine, resumes after time. Transforms game scripting ergonomics.
3. **Add timer chains**: `luna.timer.chain({1.0, fnA}, {2.0, fnB}, {0.5, fnC})` — sequential delayed execution without callback nesting.
4. **Add pause/resume**: `luna.timer.pause("name")` / `luna.timer.resume("name")` for scheduled events.
5. **Add unpauseable timers**: `luna.timer.afterReal(t, fn)` — uses wall-clock time, ignores timeScale. For UI animations during game pause.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Delta time | ✅ | ✅ | ✅ | ✅ |
| Time scale | ✅ | ❌ (manual) | ❌ | ✅ |
| Scheduled events | ✅ (named) | ❌ (manual) | ✅ (timer.performWithDelay) | ✅ |
| Timer chains | ❌ | ❌ | ❌ | ❌ |
| DT smoothing | ❌ | ❌ | ✅ | ❌ |
| Coroutine wait | ❌ | ❌ | ❌ | ❌ |

## Priority

**MEDIUM** — Delta time smoothing and coroutine wait are the most impactful. Timer chains improve scripting ergonomics significantly.
