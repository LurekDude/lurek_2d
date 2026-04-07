# tests/fixtures — Canonical Test Assets

This is the **single source of truth** for all binary and code fixtures shared across the Luna2D test suite.

## Contents

| File | Type | Used by |
|---|---|---|
| `sine_mono_44100.wav` | Audio — 440 Hz mono sine wave at 44.1 kHz | `audio_tests`, Lua audio unit tests |
| `sine_mono_441002.wav` | Audio — alternate mono WAV fixture | Audio stress tests |
| `test_dxt1.dds` | Texture — small DXT1-compressed image | `image_tests` |
| `test_dxt12.dds` | Texture — alternate DDS fixture | Image stress tests |
| `clock_fixture.rs` | Rust — deterministic mock clock for timer tests | `timer_api` Rust tests |
| `timer_api_fixture.rs` | Rust — shared timer API test helpers | `timer_api` Rust tests |

## Usage

Rust tests: `std::fs::read("tests/fixtures/file.ext")`
Lua tests: `luna.audio.newDecoder("tests/fixtures/file.wav")`

## Policy

- All new binary test assets go here, not in subdirectory fixtures folders.
- Rust code fixtures (`.rs` files) may also live here if they are shared across modules.
- Do **not** duplicate assets in `tests/rust/fixtures/` or `tests/lua/fixtures/`.
