# effect - Agent Reference

## Module Info

- Module: effect
- Group: Platform Services
- Spec: docs/specs/effect.md
- Lua API: src/lua_api/effect_api.rs
- Rust tests: tests/rust/unit/fx_tests.rs, tests/rust/unit/postfx_tests.rs, tests/rust/unit/fx_screen_tests.rs
- Lua tests: tests/lua/unit/test_image_effect.lua and related image-effect evidence suites

## Module Purpose

The effect module owns CPU-side visual effect state. It covers two adjacent areas: post-processing descriptions such as PostFxEffect, PostFxStack, and ImageEffect, and full-screen overlay state such as ambient tint, weather, fog, flash, shake, fade, and lightning.

This module exists so effect behavior can be configured, updated, and tested without tying the code to a specific GPU implementation. It describes what effects are active and how they evolve over time, while leaving shader execution, render targets, and final compositing to the renderer and Lua bridge.

## Files

- mod.rs: Declares the effect submodules and re-exports the public post-processing and overlay types.
- effect.rs: Defines PostFxEffect, the parameter bag for a single post-processing pass.
- effect_type.rs: Defines PostFxEffectType and the default parameter presets for built-in effect kinds.
- stack.rs: Defines PostFxStack, the ordered full-frame post-processing pipeline container.
- image_effect.rs: Defines ImageEffect, a smaller effect chain attached to individual image draws.
- render.rs: Generates render-command markers for beginning, ending, and applying post-processing capture.
- draw.rs: Provides CPU-side fallback drawing helpers for post-processing stacks.
- overlay.rs: Defines Overlay, the top-level screen-effect controller that aggregates ambient, atmospheric, weather, and transient screen effects.
- ambient.rs: Defines time-of-day ambient lighting state.
- atmosphere.rs: Defines cloud, fog, heat haze, vignette, film grain, and lightning state structs.
- screen_effects.rs: Defines flash, shake, and fade state.
- weather.rs: Defines weather particle types, live particles, and weather simulation state.

## Key Types

- PostFxEffect: One post-processing pass with effect type, parameter map, enabled flag, and optional custom shader handle.
- PostFxEffectType: Enum naming the built-in post-processing pass types and their default parameter sets.
- PostFxStack: Ordered full-frame post-processing pipeline with per-pass enabled flags and capture dimensions.
- ImageEffect: Ordered per-image effect chain that converts to lightweight shader pass descriptors.
- Overlay: Top-level per-frame overlay state that updates ambient, weather, flashes, fades, shake, and atmospheric effects together.
- AmbientState: Time-of-day ambient tint controller used by Overlay.
- WeatherState: Weather particle simulation state including type, wind, intensity, and live particles.
- FlashState, ShakeState, FadeState: Short-lived screen-space feedback effects.
