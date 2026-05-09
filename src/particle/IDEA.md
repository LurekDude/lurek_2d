# IDEA — src/particle

## Niezrobione TODO/WIP

- TODO(FEAT): dodać kolizje cząstek z fizyką (`setCollidesWithPhysics(world)`).
- TODO(FEAT): dodać ścieżkę GPU compute dla bardzo dużych systemów cząstek.
- TODO(PERF): rozważyć równoległą aktualizację cząstek (rayon/par_iter) po profilowaniu.
- TODO(PERF): ograniczyć alokacje w `build_render_commands` przez bufor wielokrotnego użycia.
- TODO(TEST-RUST): dodać test statystyczny rozkładu `AreaDistribution::BorderRectangle`.
- TODO(TEST-FUZZ): dodać fuzz target dla `ParticleConfig` -> `ParticleSystem::update(dt)` (brak panic).
- TODO(dedup): doprecyzować granicę odpowiedzialności `particle` vs `effect` dla efektów cząsteczkowych.
- TODO(dedup): usunąć dublowanie `lerp` (`particle::math::lerp` vs `crate::math::lerp`).
- TODO(helper): pakiet presetów `particle_presets` (fire, smoke, rain, snow, sparks).
