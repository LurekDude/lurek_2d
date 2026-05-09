# IDEA — src/light

## Niezrobione TODO/WIP

- TODO(FEAT): dodać soft shadows/penumbrę zamiast wyłącznie twardych krawędzi cienia.
- TODO(dedup): zintegrować ambient światła między `light::LightWorld.ambient` i `effect::AmbientState`.
- TODO(helper): przenieść parsery Lua-facing (`parse_blend_mode`, `parse_falloff`, `parse_shadow_filter`, `parse_light_type`) z `light2d.rs` do `lua_api/light_api.rs`.
- TODO(plugin): rozważyć opcjonalny plugin normal-map lighting (`light-normalmap`).
