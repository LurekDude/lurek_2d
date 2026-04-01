---
applyTo: "tests/**"
---

# Tests Instructions

All files in `tests/` are integration tests that import from the `luna2d` crate's public API. Unit tests stay inside `src/` modules using `#[cfg(test)]`. Tests must pass before any commit.

## Core Rules

- **Integration tests import from crate root**: `use luna2d::math::Vec2;` — never `use luna2d::src::math::Vec2`
- **Float comparisons**: `assert!((val - expected).abs() < 1e-5)` — **never** `assert_eq!` on `f32`/`f64`
- **Test naming**: snake_case, descriptive — `vec2_normalize_unit_length`, not `test1`
- **No `#[should_panic]` without a specific message** — `#[should_panic(expected = "out of bounds")]`
- **One assertion concept per test** — keep tests small and failure messages useful

## Layer / Boundary Rules

- `tests/math_tests.rs` → tests `luna2d::math` public API only
- `tests/physics_tests.rs` → tests `luna2d::physics` public API only
- `tests/graphics_tests.rs` → tests `luna2d::graphics` Color, Renderer (no window required)
- `tests/input_tests.rs` → tests `luna2d::input::KeyboardState`, `MouseState` in isolation
- `tests/audio_tests.rs` → tests `luna2d::audio::Mixer` load path (playback may fail without audio HW — that is OK)
- Never create a winit `Window` or wgpu `Surface` in tests — they require a display and GPU

## Compliance

- Every public `struct` and `fn` added to the engine must have at least one test
- Physics tests that use gravity must set `World::new(gx, gy)` — not hardcode gravity internally
- Tests must not write to disk except in `tests/fixtures/` or a temp dir

## Avoid

- `std::thread::sleep` in tests — if timing matters, use deterministic `clock.tick()` with fixed dt
- Network I/O of any kind
- `#[ignore]` without a tracking comment explaining when to re-enable
- Testing internal private functions from integration tests — promote to `pub(crate)` or add unit test in `src/`
- Depending on test execution order — each test must be independently runnable
