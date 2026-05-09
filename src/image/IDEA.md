# IDEA — src/image

## Niezrobione TODO/WIP

- TODO(TEST-FUZZ): dodać fuzz target dla `CompressedImageData::from_dds` (losowe bajty wejściowe).
- TODO(TEST-FUZZ): dodać fuzz targety dla `serial::load_image` i `serial::load_layered` (uszkodzone pliki LIMG).
- TODO(dedup): doprecyzować granicę odpowiedzialności `image/effects.rs` vs `effect/image_effect.rs` (CPU-only vs shader/post-process).
- TODO(dedup): ujednolicić atlasowanie między `image::texture_atlas` i `sprite`.
- TODO(dedup): jedno źródło prawdy dla premultiply-alpha (`image::texture` vs upload/render).
- TODO(helper): helper do cyklicznej podmiany palet (palette cycling) dla skryptów Lua.
- TODO(helper): helper Lua do nine-slice draw na bazie insets atlasu.
