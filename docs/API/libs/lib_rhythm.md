# `library.rhythm`

Lurek2D rhythm library — BPM-locked event sequencer over `lurek.audio`.

Turns audio playhead time into beat-grid scheduling for rhythm games and
music-reactive levels. Two main pieces:

* `Clock`  — beat clock with BPM, swing, ramp, and audio-source binding.
* `M.judge` — judgement window scoring for player input timing.

The clock is independent of `lurek.timer.Scheduler` (which is wall-time
based) — beat math accounts for BPM ramps and audio source seeks.

*4 functions, 0 module fields documented.*

See: [`lurek.audio`](../lua-api.md#lurekaudio) — Source playhead drives `M.fromAudio` and `:syncToAudio`, [`lurek.timer`](../lua-api.md#lurektime) — `getMicroTime` powers default `M.judge` hit time, [`lurek.event`](../lua-api.md#lureksignal) — optional emit on `rhythm.bar`/`rhythm.beat`/`rhythm.miss`, [`lurek.save`](../lua-api.md#lureksavegame) — `clock:dump` collector wiring

## Functions

### `newClock(bpm, opts)`

Build a free-running BPM clock.

### `fromAudio(source, bpm, opts)`

Build a clock anchored to an `lurek.audio` Source's playhead.

### `getBeat()`

Fractional beats since `:start()`.

### `judge(clock, division, hit_time)`

Judge a player input against the nearest beat at `division`.

**Parameters**

- `clock` *Clock*
- `division` *integer* — Beat subdivision (e.g. 4 = quarter notes, 8 = 8ths).
- `hit_time` *number?* — Time of the hit (defaults to now via `lurek.timer`).

**Returns**

- *string* — verdict — `"perfect" | "great" | "good" | "miss"`.
- *number* — error_seconds — signed offset (negative = early).
