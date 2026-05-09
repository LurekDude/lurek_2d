# IDEA — src/parallax

## Niezrobione TODO/WIP

- TODO(FEAT): wsparcie per-layer shader/post-processing.
- TODO(FEAT): velocity-based motion blur/stretch dla szybkiego autoscrollu.
- TODO(PERF): dodać mocniejszy culling kafli off-screen przy dużych rozdzielczościach/zoom.
- TODO(QUAL): podłączyć flagę `tiling` do `build_draw_calls` (obecnie używane są bezpośrednio `repeat_x/repeat_y`).
- TODO(REL): ograniczyć minimalny `tile_w/tile_h` w `set_tile_size`, żeby uniknąć milionów draw calli.
- TODO(TEST-LUA): test autoscroll + clamp interaction.
- TODO(TEST-LUA): test rzeczywistej kolejności `ParallaxSet:sortByZ`.
- TODO(TEST-RUST): test `build_draw_calls` dla custom `tile_w/tile_h`.
- TODO(TEST-RUST): test 2D tilingu dla (`repeat_x = true`, `repeat_y = true`).
- TODO(dedup): rozważyć wspólny iterator tiled draw calli między `parallax` i `tilemap`.
- TODO(helper): helper/presety `parallax_presets` dla typowych warstw tła.
