# procgen — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/procgen.md`
**Files**: 5 procedural generation algorithms

## Purpose

Stateless procedural content generation: cellular automata, flood fill, periodic Perlin noise, Poisson-disk sampling, Voronoi diagrams. All deterministic via internal Lcg PRNG.

## Current Feature Summary

- `luna.procgen.cellular(w, h, opts)` — binary map via cellular automata (cave generation)
- `luna.procgen.floodFill(grid, startX, startY, fill, match, w)` — 4-connected region fill
- `luna.procgen.perlin(w, h, sx, sy, ox, oy, px, py, seed)` — tileable Perlin noise
- `luna.procgen.poissonDisk(w, h, minDist, maxAttempts, seed)` — point distributions
- `luna.procgen.voronoi(w, h, pts, opts)` — Voronoi diagram with optional warp
- All functions are pure and deterministic (same seed = same output)
- Internal Lcg RNG (Knuth MMIX constants)
- Returns plain data tables (grids, point lists)

## Feature Gaps

1. **No BSP dungeon generation**: Binary Space Partitioning is the most common dungeon generation algorithm. Its absence is the #1 gap for roguelike games.
2. **No Wave Function Collapse**: WFC generates complex tile patterns from small examples. Very popular for procedural levels.
3. **No L-systems**: Lindenmayer systems for procedural vegetation, coral, fractals, branching structures.
4. **No room-and-corridor generation**: The standard roguelike dungeon algorithm (place rooms, connect with corridors). BSP is one approach but explicit room+corridor is more controllable.
5. **No name/word generation**: Markov chain or syllable-based name generation for RPG characters, places, items.
6. **No heightmap generation**: For isometric terrain elevation, even in 2D. Multi-octave noise exists via Perlin but no dedicated heightmap API.
7. **No graph-based generation**: Can't generate connected room graphs (for dungeon topology before spatial layout).

## Structural Issues

- **Cellular automata duplication**: Both `procgen` and `tilemap` modules implement cellular automata. Consolidate into `procgen` — the tilemap should consume procgen output, not duplicate the algorithm.
- **Uses `engine::log_messages`**: Like math/SpatialHash, this creates a dependency on engine for debug logging. Consider removing.
- **Good stateless design**: Pure functions with no side effects. Correct for procedural generation.
- **Voronoi is brute-force O(cells×seeds)**: Performance warning needed for >1000 seeds.

## Suggestions

1. **Add BSP dungeon gen**: `luna.procgen.bspDungeon(w, h, opts)` — binary space partitioning with configurable min room size, corridor width, room padding. This is the most requested proc-gen algorithm.
2. **Add room-and-corridor**: `luna.procgen.roomsAndCorridors(w, h, opts)` — random room placement + L-shaped corridor connection with overlap checks.
3. **Add WFC (simplified)**: `luna.procgen.wfc(w, h, tileRules, seed)` — simplified Wave Function Collapse for tile pattern generation. Complex but extremely valuable.
4. **Add L-systems**: `luna.procgen.lsystem(axiom, rules, iterations)` → returns string or point sequence for rendering as branching shapes.
5. **Add name generation**: `luna.procgen.generateName(minLength, maxLength, seed)` — syllable-based or Markov chain name generation. Very useful for RPGs.
6. **Remove cellular automata from tilemap**: Keep one implementation in procgen. Tilemap should call `luna.procgen.cellular()` if it needs map gen.
7. **Add connected room graph**: `luna.procgen.roomGraph(numRooms, connections, seed)` — generate connected topology before spatial layout.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy | Roguelike libs |
|---|---|---|---|---|---|
| Cellular automata | ✅ | ❌ | ❌ | ❌ | ✅ |
| Perlin noise | ✅ | ✅ (basic) | ❌ | ✅ | ✅ |
| Poisson disk | ✅ | ❌ | ❌ | ❌ | ✅ |
| Voronoi | ✅ | ❌ | ❌ | ❌ | ✅ |
| BSP dungeon | ❌ | ❌ | ❌ | ❌ | ✅ |
| WFC | ❌ | ❌ | ❌ | ❌ | ✅ |
| L-systems | ❌ | ❌ | ❌ | ❌ | ❌ |
| Name gen | ❌ | ❌ | ❌ | ❌ | ✅ |

Luna2D has a head start on built-in proc-gen. BSP and room-and-corridor would make it competitive with dedicated roguelike toolkits.

## Priority

**MEDIUM** — BSP dungeon and room-and-corridor are high-impact for the roguelike genre. WFC is ambitious but transformative. Name generation is a popular quick win.
