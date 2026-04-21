# Lurek2D Unit-Test API Coverage

*Generated: 2026-04-21T21:43:31 · Coverage requirement: explicit `@tests` annotations*

## Summary

| Metric | Value |
|--------|-------|
| Total APIs | 3654 |
| **Covered (explicit `@tests`)** | **3654 (100.0%)** |
| Heuristic-only hits | 0 (0.0%) |
| Missing explicit `@tests` | 0 (0.0%) |
| Zero-evidence APIs | 0 (0.0%) |
| Modules | 50 |

## Module Coverage

| Module | Total | Explicit | Heuristic-only | Explicit% | Missing `@tests` | Zero-evidence |
|--------|-------|----------|----------------|-----------|------------------|---------------|
| `ai` | 240 | 240 | 0 | 100.0% | 0 | 0 |
| `animation` | 45 | 45 | 0 | 100.0% | 0 | 0 |
| `audio` | 212 | 212 | 0 | 100.0% | 0 | 0 |
| `automation` | 28 | 28 | 0 | 100.0% | 0 | 0 |
| `camera` | 36 | 36 | 0 | 100.0% | 0 | 0 |
| `collision` | 4 | 4 | 0 | 100.0% | 0 | 0 |
| `compute` | 67 | 67 | 0 | 100.0% | 0 | 0 |
| `data` | 57 | 57 | 0 | 100.0% | 0 | 0 |
| `dataframe` | 64 | 64 | 0 | 100.0% | 0 | 0 |
| `debugbridge` | 14 | 14 | 0 | 100.0% | 0 | 0 |
| `devtools` | 48 | 48 | 0 | 100.0% | 0 | 0 |
| `docs` | 75 | 75 | 0 | 100.0% | 0 | 0 |
| `ecs` | 47 | 47 | 0 | 100.0% | 0 | 0 |
| `effect` | 142 | 142 | 0 | 100.0% | 0 | 0 |
| `engine` | 10 | 10 | 0 | 100.0% | 0 | 0 |
| `event` | 22 | 22 | 0 | 100.0% | 0 | 0 |
| `filesystem` | 54 | 54 | 0 | 100.0% | 0 | 0 |
| `globe` | 44 | 44 | 0 | 100.0% | 0 | 0 |
| `graph` | 111 | 111 | 0 | 100.0% | 0 | 0 |
| `i18n` | 31 | 31 | 0 | 100.0% | 0 | 0 |
| `image` | 68 | 68 | 0 | 100.0% | 0 | 0 |
| `input` | 80 | 80 | 0 | 100.0% | 0 | 0 |
| `light` | 83 | 83 | 0 | 100.0% | 0 | 0 |
| `log` | 18 | 18 | 0 | 100.0% | 0 | 0 |
| `math` | 204 | 204 | 0 | 100.0% | 0 | 0 |
| `minimap` | 56 | 56 | 0 | 100.0% | 0 | 0 |
| `mods` | 40 | 40 | 0 | 100.0% | 0 | 0 |
| `network` | 38 | 38 | 0 | 100.0% | 0 | 0 |
| `parallax` | 43 | 43 | 0 | 100.0% | 0 | 0 |
| `particle` | 84 | 84 | 0 | 100.0% | 0 | 0 |
| `pathfind` | 65 | 65 | 0 | 100.0% | 0 | 0 |
| `patterns` | 170 | 170 | 0 | 100.0% | 0 | 0 |
| `physics` | 147 | 147 | 0 | 100.0% | 0 | 0 |
| `pipeline` | 60 | 60 | 0 | 100.0% | 0 | 0 |
| `procgen` | 29 | 29 | 0 | 100.0% | 0 | 0 |
| `raycaster` | 42 | 42 | 0 | 100.0% | 0 | 0 |
| `render` | 183 | 183 | 0 | 100.0% | 0 | 0 |
| `save` | 22 | 22 | 0 | 100.0% | 0 | 0 |
| `scene` | 53 | 53 | 0 | 100.0% | 0 | 0 |
| `serial` | 10 | 10 | 0 | 100.0% | 0 | 0 |
| `spine` | 20 | 20 | 0 | 100.0% | 0 | 0 |
| `sprite` | 18 | 18 | 0 | 100.0% | 0 | 0 |
| `system` | 26 | 26 | 0 | 100.0% | 0 | 0 |
| `terminal` | 82 | 82 | 0 | 100.0% | 0 | 0 |
| `thread` | 37 | 37 | 0 | 100.0% | 0 | 0 |
| `tilemap` | 134 | 134 | 0 | 100.0% | 0 | 0 |
| `timer` | 43 | 43 | 0 | 100.0% | 0 | 0 |
| `tween` | 35 | 35 | 0 | 100.0% | 0 | 0 |
| `ui` | 363 | 363 | 0 | 100.0% | 0 | 0 |
| `window` | 50 | 50 | 0 | 100.0% | 0 | 0 |

## Missing Explicit `@tests` Coverage

> These APIs still need an explicit `-- @tests ...` annotation in at least one unit-test `it()` block.

## Zero-Evidence APIs

> These APIs are neither explicitly annotated nor referenced heuristically in unit tests.

## Annotation Convention

Add `-- @tests <lua_name>` inside any `it()` block to explicitly declare
which API that test exercises:

```lua
it("getDelta returns a number", function()
    -- @tests lurek.timer.getDelta
    local dt = lurek.timer.getDelta()
    expect_type("number", dt)
end)

it("World:step advances simulation", function()
    -- @tests World:step
    world:step(1/60)
end)
```

Multiple `@tests` annotations per `it()` block are allowed.  
Run `python tools/audit/unit_test_api_coverage.py --save` to regenerate this report.