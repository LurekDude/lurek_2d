# `rhythm` — Agent Reference (Lunasome)

| Property       | Value                                                                                                                                                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 — Lunasome (pure Lua)                                                                                                                                                 |
| **Source**     | `library/rhythm/init.lua`                                                                                                                                                    |
| **Lua Tests**  | `tests/lua/library/test_library_rhythm.lua`                                                                                                                                  |
| **Depends on** | `lurek.audio` (`Source:getPosition` for `fromAudio`/`syncToAudio`), `lurek.timer.getMicroTime` (default `judge` time), `lurek.event` (optional `rhythm.beat/bar/miss` emits) |
| **Status**     | full                                                                                                                                                                         |

## Purpose

BPM-locked event sequencer that turns `lurek.audio` playhead time into beat-grid
scheduling for rhythm games and music-reactive levels. Adds the missing
beat/bar/swing/judgement abstractions on top of audio sources and Δt timers.

## Public API

### Beat clock
- `M.newClock(bpm, opts?)` — `{subdivision=4, swing=0, latency_ms=0}`
- `M.fromAudio(source, bpm, opts?)` — anchor to an audio source's playhead
- `clock:setBpm(bpm) / rampBpm(target, seconds) / getBpm()`
- `clock:setSwing(amount)`
- `clock:start() / stop() / isRunning()`
- `clock:update(dt)`
- `clock:syncToAudio(source)` — re-anchor after a Source seek

### Beat queries
- `clock:getBeat()` / `getBar()`
- `clock:getPhase(division?) -> 0..1`
- `clock:beatTimeRemaining(division?) -> seconds`
- `clock:isOnBeat(division?, tolerance?)`
- `clock:nearestBeat(division?) -> beat_number, error_seconds`

### Sequencer
- `clock:every(division, fn) -> handle`
- `clock:at(beat, fn) -> handle`
- `clock:pattern("x..x..xx", fn) -> handle`
- `clock:cancel(handle)` / `clock:cancelAll()`

### Judgement scoring
- `M.judge(clock, division, hit_time?) -> verdict, error_seconds`
- `M.setJudgementWindows({perfect, great, good})`
- `M.getJudgementWindows()`

### Diagnostics
- `clock:dump()`

## Dependencies

- **`lurek.audio` Source** — when constructed via `M.fromAudio`, the clock
  reads `Source:getPosition()` each `update` to stay phase-locked. If the
  binding is missing, the clock degrades to a wall-time clock.
- **`lurek.timer.getMicroTime`** — default `M.judge` hit time. Falls back to
  `os.clock()` when missing.
- **`lurek.event`** — emits `rhythm.beat`, `rhythm.bar`, and `rhythm.miss`
  events when present; entirely optional.

## Status

`full` — clock, BPM ramp, swing knob, audio sync, every/at/pattern sequencer,
and judge scoring all implemented and tested.

## Examples

See `content/library/rhythm/example.lua` for an audio-driven beat clock with
`every`, `pattern`, and `judge` exercised on a small input timing demo.

## Notes

- `clock:at(beat, fn)` raises if the requested beat is in the past — use
  `clock:every` for periodic firing.
- `clock:pattern("x..x", fn)` interprets the string as one full bar — string
  length determines the subdivision granularity, **not** the constructor's
  `subdivision` opt.
- Negative judgement `error_seconds` means the hit was early.
- `swing` is currently informational; full swing-shifted beat math will land
  alongside an audio backend that exposes per-grain timing.
