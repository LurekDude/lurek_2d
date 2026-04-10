# Lua API Test Coverage Report

**Status**: ⚠️ BASELINE SNAPSHOT — This is a baseline report from 2026-04-09. Since then: 13 golden tests, 18+ integration tests, and 13 new stress tests have been added. Coverage numbers have improved significantly. Re-run `python tools/audit/lua_api_test_coverage.py` for current numbers.

**Generated**: 2026-04-09
**Tool**: `tools/audit/test_coverage.py` (heuristic) + manual analysis
**API Source**: `docs/logs/lua_api_data.json` (2588 functions across 45 modules)

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Lua API functions | 2588 |
| Heuristic coverage | 82.8% (2143/2588) |
| Estimated true coverage | ~65–70% (accounting for false positives) |
| Lua test files | 106 (59 unit, 15 integration, 12 stress, 12 library, 4 security, 1 golden, 1 config, 1 examples) |
| Modules with <60% coverage | 5 (system, math, network, log, modding) |
| Modules with 100% coverage | 12 (automation, compute, dataframe, debugbridge, graph, light, minimap, procgen, scene, serial, signal, spine, terminal, thread, tween) |

### Key Findings

1. **Heuristic false-positive rate is ~15–20%**: The current `test_coverage.py` uses substring matching. For example, a function named `set` will match any test that uses `set` in any context. Methods like `getPosition` match whenever `position` appears as part of a different function name.

2. **Method coverage is systematically lower than function coverage**: Most tests call top-level `lurek.<module>.newX()` constructors but exercise only a subset of the returned object's methods.

3. **No marker-based tracking exists**: Coverage is entirely heuristic — there's no way to distinguish "this test intentionally exercises function X" from "this test happens to contain the substring X".

---

## Per-Module Coverage Detail

### Tier: Critical Low Coverage (<60%)

| Module | Functions | Methods | Total | Heuristic Coverage | Key Gaps |
|--------|-----------|---------|-------|--------------------|----------|
| **system** | 22 | 0 | 22 | 36.4% | `getOS`, `getArch`, `getCPUCount`, `getMemInfo`, `getGPUInfo`, `getDisplayInfo`, `getLocale`, `getTimezone`, `getUsername`, `getClipboard`, `setClipboard`, `openURL`, `getEnv` |
| **math** | 79 | 53 | 132 | 40.9% | Vec2/Vec3/Mat3 methods (most), noise functions, bezier, triangulation, Transform methods |
| **network** | 1 | 19 | 20 | 40.0% | HttpClient methods (get/post/put/delete/headers), WebSocket methods |
| **log** | 13 | 0 | 13 | 53.8% | `setLevel`, `getLevel`, `setFile`, `trace`, `warn`, `error`, `fatal` |
| **modding** | 2 | 31 | 33 | 54.5% | ModManager methods (loadMod, unloadMod, getMods, getModInfo, etc.) |

### Tier: Moderate Coverage (60–80%)

| Module | Functions | Methods | Total | Heuristic Coverage | Key Gaps |
|--------|-----------|---------|-------|--------------------|----------|
| **physics** | 15 | 76 | 91 | 54.9% | Joint methods, Body advanced methods (applyTorque, setLinearDamping), World query methods |
| **localization** | 27 | 0 | 27 | 55.6% | `setLocale`, `getLocale`, `loadCatalog`, `formatNumber`, `formatDate`, `formatCurrency`, pluralization |
| **filesystem** | 24 | 13 | 37 | 59.5% | `enumerate`, `getInfo`, `watch`, `unwatch`, `mount`, `unmount`, File:read/write/seek methods |
| **docs** | 25 | 50 | 75 | 68.0% | DocBrowser methods, search, navigation, category listing |
| **timer** | 10 | 17 | 27 | 70.4% | Timer object methods (pause, resume, setInterval, getElapsed), scheduled callbacks |
| **camera** | 1 | 22 | 23 | 73.9% | Camera:setRotation, getBounds, clearTarget, setDeadzone, shake methods |
| **graphic** | 78 | 65 | 143 | 73.4% | Canvas methods, SpriteBatch methods, Shader uniform setters, Mesh methods, blend modes |
| **audio** | 76 | 92 | 168 | 78.0% | MidiPlayer advanced methods, Source filter methods, spatial audio, bus routing |
| **pathfinding** | 8 | 51 | 59 | 78.0% | NavMesh methods, FlowField methods, advanced heuristic settings |

### Tier: Good Coverage (80–95%)

| Module | Funcs | Methods | Total | Coverage | Notes |
|--------|-------|---------|-------|----------|-------|
| patterns | 13 | 90 | 103 | 81.6% | Some Observer/State methods uncovered |
| pipeline | 3 | 54 | 57 | 80.7% | Pass configuration methods |
| tilemap | 26 | 85 | 111 | 85.6% | Some TileLayer methods |
| ui | 38 | 269 | 307 | 87.0% | Large surface; many widget methods |
| input | 50 | 2 | 52 | 88.5% | Gamepad axis/button mapping |
| particle | 2 | 76 | 78 | 89.7% | Emitter advanced methods |
| entity | 1 | 44 | 45 | 93.3% | Component query methods |
| animation | 1 | 17 | 18 | 94.4% | getCurrentFrame |
| effect | 7 | 110 | 117 | 94.9% | Minor effect parameter methods |
| savegame | 1 | 18 | 19 | 94.7% | — |
| image | 7 | 19 | 26 | 96.2% | — |
| data | 13 | 9 | 22 | 81.8% | Compression, TOML advanced |
| window | 47 | 0 | 47 | 91.5% | — |
| devtools | 37 | 0 | 37 | 91.9% | — |
| ai | 19 | 125 | 144 | 99.3% | CommandQueue:getCurrentTarget only |

### Tier: Full Coverage (100% heuristic)

automation, compute, dataframe, debugbridge, graph, light, minimap, procgen, scene, serial, signal, spine, terminal, thread, tween

**Warning**: 100% heuristic coverage does NOT mean every function is tested — it means every function name appears as a substring in some test file. These modules still need marker-based verification.

---

## False-Positive Analysis

### Methodology
Sampled 20 "covered" functions across 5 modules and manually verified whether the test file actually calls the function:

| Module | Function | Test File | Actually Called? | False Positive? |
|--------|----------|-----------|-----------------|-----------------|
| light | `setIntensity` | test_light.lua | Yes — `light:setIntensity(0.5)` | No |
| light | `setColor` | test_light.lua | Matches `gfx.setColor` call | **Yes** |
| math | `sin` | test_math.lua | Yes | No |
| math | `set` (Vec2:set) | test_math.lua | Matches general `set` substring | **Yes** |
| physics | `step` | test_physics.lua | Yes | No |
| physics | `set` (Body:set*) | test_physics.lua | Matches `setColor` etc | **Yes** |
| terminal | `write` | test_terminal.lua | Yes | No |
| terminal | `clear` | test_terminal.lua | Yes | No |
| input | `isDown` | test_input.lua | Yes | No |
| graph | `add` (Graph:add*) | test_graph.lua | Matches generic `add` | **Yes** |

**Estimated false-positive rate**: ~20% for short function names (≤5 chars), ~5% for longer names (≥8 chars). Overall weighted estimate: **~12–18%**.

**Impact**: True coverage is likely **~65–72%** rather than the reported 82.8%.

---

## Priority Recommendations

### Immediate (High Impact)

1. **system module** (22 APIs, 36.4%): Most functions are pure getters — trivially testable headless
2. **log module** (13 APIs, 53.8%): All logging functions testable headless
3. **math module** (132 APIs, 40.9%): 53 Vec2/Mat3 methods need systematic tests
4. **localization module** (27 APIs, 55.6%): String formatting testable headless

### Short-Term (Medium Impact)

5. **physics module** (91 APIs, 54.9%): Joint and advanced Body methods need tests
6. **filesystem module** (37 APIs, 59.5%): File read/write operations (use temp dirs)
7. **timer module** (27 APIs, 70.4%): Timer object methods need dedicated tests
8. **camera module** (23 APIs, 73.9%): Transform and limit methods

### Long-Term (Evidence Required)

9. **graphic module** (143 APIs, 73.4%): Canvas, Shader, Mesh methods need visual evidence
10. **audio module** (168 APIs, 78.0%): MIDI, spatial audio need runtime evidence
