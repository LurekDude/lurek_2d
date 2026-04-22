# `cinematic` â€” Agent Reference (Lunasome)

| Property       | Value                                                                                                                                                                       |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 â€” Lunasome (pure Lua)                                                                                                                                                |
| **Source**     | `library/cinematic/init.lua`                                                                                                                                                |
| **Lua Tests**  | `tests/lua/library/test_library_cinematic.lua`                                                                                                                              |
| **Depends on** | `lurek.tween`, `lurek.camera`, `lurek.audio`, `lurek.event` (each clip kind degrades to a no-op when its binding is unavailable), `lurek.filesystem` + `lurek.serial` (TOML loader) |
| **Status**     | partial â€” core timeline works; per-frame tween easing is delegated to `lurek.tween`                                                                                         |

## Purpose

Multi-track scrubbable cutscene timeline that composes engine primitives
(`lurek.tween`, `lurek.camera`, `lurek.audio`, `lurek.event`,
`library.dialog`) into a single play / pause / seek / scrub / skip-to-label
authoring surface. Distinct from `lurek.scene` (push/pop transitions) and
`lurek.tween` (single-property forward-only tween).

## Public API

### Timeline lifecycle
- `M.newTimeline(opts?)` â€” `{loop, autoStart, timeScale}`
- `M.fromToml(path)` / `M.fromTable(spec)`
- `tl:play() / pause() / resume() / stop()`
- `tl:isPlaying() / isFinished()`

### Scrubbing & seek
- `tl:setTime(t) / getTime() / getDuration()`
- `tl:scrub(delta) / rewind()`
- `tl:setTimeScale(s)` â€” supports negative for reverse

### Track authoring
- `tl:track(name) -> Track` (get-or-create)
- `tl:tracks()`
- `track:add(clip)`
- `track:tween(at, duration, target, props, easing?)`
- `track:cameraTo(at, duration, x, y, zoom?, easing?)`
- `track:dialog(at, line)`
- `track:audio(at, source, opts?)`
- `track:shake(at, duration, intensity)`
- `track:signal(at, name, ...)`
- `track:call(at, fn, opts?)` â€” pass `{reversible=true}` for scrub safety
- `track:wait(at, predicate_fn)`
- `track:remove(clip)`

### Update / hooks
- `tl:update(dt)` â€” call once per frame
- `tl:onComplete(fn) -> handle`
- `tl:onTrackEnter(name, fn) -> handle`
- `tl:offHandle(handle)`
- `tl:setDialogHandler(fn)` â€” sink for `track:dialog` clips

### Skip & branch
- `tl:label(at, name)` / `tl:skipTo(label)`
- `tl:branch(at, predicate, child_timeline)`
- `tl:export()`

## Dependencies

All `lurek.*` consumer clips degrade gracefully:

- `lurek.tween` â€” preferred for `track:tween`; falls back to direct property
  assignment when missing.
- `lurek.camera` â€” `setPosition`, `setZoom`, `shake` calls are best-effort.
- `lurek.audio` â€” `play(source, opts)` invocation; missing binding = no-op.
- `lurek.event` â€” `push(name, ...)`; missing binding = no-op.
- `lurek.filesystem` + `lurek.serial` â€” only required for `M.fromToml`.

## Status

`partial` â€” clip firing, scrubbing, label skip, branch predicates, and save
export work. Per-tween-frame easing depends on `lurek.tween` doing its own
update; this library only fires the start clip.

## Examples

See `library/cinematic/example.lua` for a small intro cutscene with
camera moves, shake, dialog, and label skip.

## Notes

- **Reversibility**: `track:tween/wait/cameraTo` are reversible by default.
  `track:audio/dialog/signal/shake` are one-shot (non-reversible). To enable
  backward scrub through a `track:call` clip, pass `{reversible=true}`.
- **Wait clip**: blocks the timeline until its predicate returns true. The
  playhead is clamped at the wait-clip's `at` and progress pauses
  automatically.
- **Branch timeline**: when the playhead crosses the branch `at`, the child
  timeline is `:play()`'d only if the predicate returns true. The parent
  always runs `child:update(dt)` while it exists.
- The library does **not** call `lurek.timer.Scheduler` â€” the timeline owns
  its own clock driven by the caller's `dt`.

