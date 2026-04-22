# `library.cinematic` *(partial)*

Lurek2D cinematic library — multi-track scrubbable cutscene timeline.

Sequences `lurek.tween`, `lurek.camera`, `lurek.audio`, `lurek.event`,
and `library.dialog` clips into a single time-positioned timeline that
supports play/pause/seek/scrub/skip-to-label/branch.

Each track is a sorted list of clips: `{at, duration, kind, params,
on_apply, on_revert}`. The timeline owns its own clock — it does not use
`lurek.timer.Scheduler`.

*20 functions, 0 module fields documented.*

See: [`lurek.tween`](../lua-api.md#lurektween) — backbone for `track:tween` clips, [`lurek.camera`](../lua-api.md#lurekcamera) — consumed by `track:cameraTo` / `track:shake`, [`lurek.audio`](../lua-api.md#lurekaudio) — consumed by `track:audio` (one-shot fire), [`lurek.event`](../lua-api.md#lureksignal) — consumed by `track:signal`, [`lurek.filesystem`](../lua-api.md#lurekfs) — timeline TOML loader (`fromToml`), [`lurek.serial`](../lua-api.md#lurekcodec) — JSON serialisation for `tl:export`, [`lurek.save`](../lua-api.md#lureksavegame) — collector wiring for export/restore

## Functions

### `add(clip)`

Add a generic clip table.

**Parameters**

- `clip` *table* — `{at, duration, kind, params, on_apply, on_revert}`.

### `tween(at, duration, target, props, easing)`

Tween clip. Wraps `lurek.tween` if available; always applies final value if the engine binding is missing (so logic-only tests still pass).

### `cameraTo(at, duration, x, y, zoom, easing)`

Camera move clip.

### `shake(at, duration, intensity)`

Camera shake clip.

### `dialog(at, line)`

Dialog clip — fires once forward only.

### `audio(at, source, opts)`

Audio clip — fires once forward only.

### `signal(at, name, ...)`

Signal clip — emits via `lurek.event.push` (or queues for later read).

### `call(at, fn, opts)`

Generic Lua callback. Mark `reversible = true` to allow backward seeks.

### `wait(at, predicate_fn)`

Wait clip — pauses the timeline until `predicate_fn()` returns true.

### `remove(clip)`

Remove a clip by reference.

### `newTimeline(opts)`

Create a new timeline.

**Parameters**

- `opts` *table?* — `{loop=false, autoStart=false, timeScale=1.0}`.

**Returns**

- *Timeline*

### `fromToml(path)`

Load a timeline from a TOML file via `lurek.filesystem.read` + `lurek.serial.fromToml`.

### `fromTable(spec)`

Build a timeline from a declarative spec table.

### `track(name)`

Get-or-create a track by name.

### `_recompute_duration()`

Recompute total duration from the latest clip end.

### `setDialogHandler(fn)`

Bind a dialog handler `fn(line)` invoked by `track:dialog` clips.

### `label(at, name)`

Add a labelled cue point.

### `branch(at, predicate, child)`

Add a branch — `child_timeline` runs at `at` only when `predicate(tl)` is true.

### `update(dt)`

Advance timeline by `dt`. Call once per frame from `lurek.process`.

### `setTime(t)`

Seek to absolute time.
