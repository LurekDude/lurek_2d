# IDEA — src/sprite

## Niezrobione TODO/WIP

- TODO(FEAT): runtime atlas packing (`newAtlasPacker`) Lua API - CPU packing już istnieje w `image/texture_atlas.rs`, wymaga Lua bindings.
- TODO(FEAT): wsparcie normal-map/lit sprites w integracji z `light`/render pipeline.
- TODO(FEAT): opcjonalny szybki format binarny atlasów dla dużych paczek assetów.
- TODO(PERF): ograniczyć alokacje w `SpriteSheet::get_row/get_column`.
- TODO(TEST): rozszerzyć testy parserów atlasów (Aseprite/TexturePacker, error paths).
- TODO(TEST-FUZZ): dodać fuzz targety parserów JSON atlasów.
- TODO(dedup): doprecyzować overlap parserów Aseprite (`sprite` vs `animation`).
- DONE(helper): dodano helper `sprite_animator` dla częstego wzorca sprite-sheet playback (`library/sprite/sprite_animator.lua`).
