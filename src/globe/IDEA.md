# Globe Module — Ideas & Future Work

## Inspiration
XCOM UFO Defense 1994 Geoscape + Europa Universalis — a projection-correct 2D view of a sphere divided into
named, navigable provinces with fog of war, markers, and great-circle paths.

## Implemented
- Province topology (adjacency, path-finding, custom attrs)
- Orbit camera + orthographic-style projection (unit sphere → screen space)
- Day/night lighting with soft terminator
- Per-faction fog-of-war (bit-vector, zero-copy Lua serialization)
- Markers, labels, layers (thematic color overlays)
- Arc rendering (great-circle routes, range rings)
- TOML province map loader + PNG stub
- Lua API (`lurek.globe.*`)

## Near-term ideas
- [ ] Province texture support (texture atlas, UV coordinates from TOML)
- [ ] Atmosphere halo (additive ring around hemisphere silhouette)
- [ ] Heat-map layer (gradient color from float attribute)
- [ ] Animated markers (pulsing, rotating icons)
- [ ] Fog-of-war partial visibility (scouted vs. fully visible)
- [ ] Sector / strategic-zone grouping (aggregate multiple provinces)
- [ ] Province border smoothing (bezier interpolation)
- [ ] Fog of war mask serialization helpers (base64 compact form)

## Medium-term ideas
- [ ] PNG province map loader (flood-fill ID extraction, color-table mapping)
- [ ] Voronoi province generation (procedural, from seed points)
- [ ] Animated globe rotation (auto-spin spec field)
- [ ] Multi-globe views (split-screen tactical + strategic)
- [ ] Province outline font rasterization (labels that follow curves)
- [ ] Strategic AI hooks (reachability maps cached per faction)

## Long-term / plugin candidates
- [ ] 3D raycasted globe mode (raycaster + sphere intersection, A-03 compliant)
- [ ] Live texture streaming from game assets
- [ ] Networked shared globe state (B-04 Channel-based sync)
- [ ] Province mesh export for procedural game content

## Architecture notes
- A-03: 2D draw calls only — DrawConvexFan + Polyline + Circle. No wgpu 3D pipeline.
- B-04: GlobeRegistry is not Send. For multi-VM access, serialize via Channel.
- B-05: Province maps use TOML; JSON export is fine for external interop.
- MAX_PROVINCES = 8192 (soft cap, extend by bumping FogMask::WORD_COUNT if needed).
