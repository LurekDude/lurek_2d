# Advanced Test Analytics Design

**Status**: ❌ NOT YET IMPLEMENTED — This is a design document for a future `tools/audit/test_analytics.py` script that would produce per-module coverage dashboards. The underlying data (coverage scanner, markers, evidence tags) is in place; only the aggregator script is missing.

**Purpose**: Design a comprehensive test analytics system that aggregates coverage data from multiple sources (markers, describe-blocks, heuristics, evidence tags) into grouped, categorized reports with per-module and per-method breakdowns.

---

## Data Sources

The analytics system aggregates from:

| Source | Data | Tool |
|--------|------|------|
| `lua_api_data.json` | API surface: all modules, functions, methods, param counts | `gen_lua_api_data.py` |
| `@covers` marker scan | Explicit per-function coverage | `lua_api_test_coverage.py` |
| describe-block scan | Per-method test count, error tests, nil tests | Extend `lua_api_test_coverage.py` |
| `@evidence` tags | Which functions have visual/audio/file evidence | Same scanner |
| heuristic scan | Fallback coverage estimate | Same scanner |
| `@stress` tags | Which functions are stress-tested | Same scanner |
| `@golden` tags | Which functions have golden baselines | Same scanner |
| test file count | How many test files exist per category | Harness.rs parse |

---

## Proposed Script: `tools/audit/test_analytics.py`

### Invocation

```powershell
python tools/audit/test_analytics.py                   # full report to stdout
python tools/audit/test_analytics.py --html            # HTML dashboard → docs/quality/test_analytics.html
python tools/audit/test_analytics.py --json            # JSON export → docs/logs/test_analytics.json
python tools/audit/test_analytics.py --module physics  # single module deep-dive
python tools/audit/test_analytics.py --category tier1  # all Tier 1 modules
python tools/audit/test_analytics.py --worst 10        # 10 worst-covered modules
python tools/audit/test_analytics.py --trend           # compare to last run (JSON delta)
```

---

## Report Sections

### 1. Executive Summary

```
=========================================================
  LUREK2D TEST ANALYTICS REPORT — 2026-04-09
  API Surface: 48 modules, 2588 functions
  Test Files:  106 Lua, 48 Rust unit, 15 integration, 12 stress, 12 golden
=========================================================

OVERALL COVERAGE
  Marker:     12.3% (319 / 2588 explicit)
  Heuristic:  80.5% (2079 / 2588 estimated)
  Evidence:    8.1% (210 / 2588 have any evidence)
  Error tests:  6.4% (166 / 2588 have error tests)
  Describe:    18.2% (471 / 2588 in named describe blocks)

TIER BREAKDOWN
  Tier 1 (25 modules):  82.1% heuristic  11.4% marker
  Tier 2 (14 modules):  77.3% heuristic   9.8% marker
  Lua API (9 aux):       79.6% heuristic  16.2% marker
```

### 2. Module Category Groups

Group modules by functional category for better navigation:

```
RENDERING MODULES (graphic, light, camera, particle, postfx, effect, tilemap, minimap)
AUDIO MODULES (audio)
PHYSICS MODULES (physics)
AI/LOGIC MODULES (ai, pathfinding, graph, automation, patterns)
ENTITY/SCENE MODULES (entity, scene, animation, spine, tween)
DATA/PERSISTENCE (data, dataframe, serial, savegame, filesystem, image)
NETWORKING (network)
SYSTEM (system, window, input, timer, event, signal, thread)
SCRIPTING AIDS (log, localization, ui, gui, modding, devtools, docs)
MATH/COMPUTE (math, compute, procgen, raycaster)
```

### 3. Per-Module Detail Table

```
MODULE          FUNCS  MARKER  HEUR    EVIDENCE  ERROR   STRESS  GOLDEN  SCORE
─────────────── ─────  ──────  ──────  ────────  ──────  ──────  ──────  ─────
[RENDERING]
graphic          143    7.0%   88.1%   16 pixel  12/143    1      yes    B
light             45    0.0%   71.1%    0 NONE!   2/45     0       no    C- ⚠
camera            52   11.5%   82.7%    2 state   5/52     1       no    B-
particle          38    0.0%   78.9%    0 pixel?   1/38    0       no    C
postfx            31    0.0%   61.3%    0 NONE!   0/31     0       no    D ⚠
tilemap          111    3.6%   79.3%    2 pixel   4/111    1       yes   C+
...
[AUDIO]
audio            168    5.4%   83.9%   10 state  12/168    0       no    C+
...
[MATH/COMPUTE]
math             132    0.0%   31.8%    0          2/132   1       yes   D- ⚠
compute           28   17.9%   91.1%    0          2/28    1       no    B-
```

### 4. Scoring System

Each module gets a letter grade based on weighted criteria:

| Criterion | Weight | 0 pts | 1 pt | 2 pts |
|-----------|--------|-------|------|-------|
| Heuristic coverage | 20 | <50% | 50-79% | ≥80% |
| Marker coverage | 25 | <5% | 5-29% | ≥30% |
| Evidence present | 20 | None | 1-2 functions | ≥3 functions |
| Error tests | 15 | None | 1-2 | ≥3 |
| Stress test exists | 10 | No | — | Yes |
| Golden test exists | 10 | No | — | Yes |

Score 0–10:
- 9-10: A (excellent)
- 7-8: B (good)
- 5-6: C (adequate)
- 3-4: D (needs work) ⚠
- 0-2: F (critical gap) 🚨

### 5. Uncovered Function List

```
UNCOVERED FUNCTIONS (marker+heuristic both miss)
  math:            Vec2:rotate, Vec3:cross, Mat3:inverse, noise3D, ... (89 functions)
  light:           setBlendMode, setShadowQuality, ... (13 functions)
  physics:         World:queryPolygon, Body:getMass, ... (22 functions)

USE: python tools/audit/test_analytics.py --suggest --module math
```

### 6. Evidence Coverage Detail

```
EVIDENCE COVERAGE
  Canvas pixel evidence:  16 functions in graphic, 4 in image, 2 in animation
  File-based evidence:    12 functions in filesystem, 8 in savegame, 3 in data
  State readback:         45 functions across 8 modules
  Runtime smoke:           4 functions (light×0, particle×0, audio×0, postfx×0)

  ⚠ CRITICAL: light module has 0 visual evidence (reported UI gap)
  ⚠ CRITICAL: particle module has 0 visual evidence
  ⚠ WARNING:  postfx module has 0 pixel evidence
```

### 7. Test-per-Function Distribution

```
TESTS-PER-FUNCTION DISTRIBUTION 
  0 tests (uncovered):   512 functions (19.8%)
  1 test:               1024 functions (39.6%)
  2-3 tests:             718 functions (27.7%)
  4-5 tests:             244 functions  (9.4%)
  6+ tests:               90 functions  (3.5%)

  Under-tested (1 test): prioritize error + nil tests for these
```

### 8. Trend Comparison

```
CHANGE SINCE LAST RUN (2 weeks ago)
  Marker coverage:    +2.1% (was 10.2%, now 12.3%)
  Evidence coverage:  +0.8% (was  7.1%, now  8.1%)
  New tests added:          +24 (was 82, now 106)

  REGRESSIONS: None
  NEW UNCOVERED: 47 functions (API expanded since last run)
```

### 9. Per-Category Totals

```
CATEGORY TOTALS
                    Modules  Functions  Marker%  Heuristic%  Evidence  Grade
  Rendering            8       558      4.8%      81.2%        22      C+
  Audio                1       168      5.4%      83.9%        10      C+
  Physics              1        91      8.8%      54.9%         4      C-
  AI/Logic             4       358     16.2%      84.4%         6      B-
  Entity/Scene         5       248      6.5%      79.8%         8      C+
  Data/Persistence     6       203     11.3%      85.7%        25      B-
  Networking           1        30      0.0%      40.0%         0      D ⚠
  System               7       242      3.7%      77.7%        14      C
  Scripting Aids       5       198      4.5%      75.3%         3      C-
  Math/Compute         4       261      4.2%      59.0%         0      C-
```

---

## Implementation: `tools/audit/test_analytics.py`

### Architecture

```python
"""
test_analytics.py — Lurek2D comprehensive test analytics

Data pipeline:
  1. load_api_surface()      → {module → [functions]}
  2. scan_coverage()         → marker_map, heuristic_map, describe_map
  3. scan_evidence()         → evidence_map {fn → [tier, ...]}
  4. load_test_counts()      → test_file_count, total_it_count
  5. build_module_reports()  → per-module aggregated data
  6. compute_grades()        → letter grade per module
  7. render_report(format)   → stdout | JSON | HTML
"""
```

### Key Data Structures

```python
@dataclass
class FunctionCoverage:
    full_name: str          # "lurek.physics.newWorld" or "PhysicsWorld:addBody"
    is_marker_covered: bool
    is_heuristic_covered: bool
    describe_test_count: int
    has_error_test: bool
    has_nil_test: bool
    evidence_types: list[str]  # ["pixel", "state", "file", "smoke"]
    has_stress_test: bool
    has_golden_test: bool
    test_files: list[str]

@dataclass 
class ModuleCoverage:
    name: str
    category: str
    tier: int
    source_file: str
    function_count: int
    marker_covered: int
    heuristic_covered: int
    evidence_count: int
    error_test_count: int
    functions: list[FunctionCoverage]
    grade: str              # A B C D F
    score: float            # 0-10
    warnings: list[str]
```

### HTML Dashboard Structure

```html
<!DOCTYPE html>
<html>
<head><title>Lurek2D Test Analytics</title></head>
<body>
  <!-- Executive Summary cards (4 big numbers) -->
  <section id="summary">
    <card>2588 API Functions</card>
    <card>80.5% Heuristic Coverage</card>  
    <card>12.3% Marker Coverage</card>
    <card>8.1% Evidence Coverage</card>
  </section>
  
  <!-- Module table with sortable columns + color-coded grades -->
  <section id="modules">
    <table id="module-table" data-sortable>
      <tr>Module | Functions | Marker | Heuristic | Evidence | Grade ▲</tr>
      ...rows sorted by grade ascending (worst first)...
    </table>
  </section>
  
  <!-- Category bar chart (horizontal bars per category) -->
  <section id="categories">
    <!-- SVG bar chart: rendering/audio/physics... vs coverage% -->
  </section>
  
  <!-- Uncovered function explorer (filter by module) -->
  <section id="uncovered">
    <select id="module-filter">...</select>
    <table>Function | Heuristic | Marker | Suggestion</table>
  </section>
  
  <!-- Distribution histogram (tests per function) -->
  <section id="distribution">
    <!-- SVG histogram: 0,1,2-3,4-5,6+ tests/function -->
  </section>
  
  <!-- Trend chart (if previous JSON exists) -->
  <section id="trend">
    <!-- SVG line chart: marker% and evidence% over time -->
  </section>
</body>
</html>
```

---

## JSON Output Schema

```json
{
  "generated": "2026-04-09T00:00:00Z",
  "version": "1.0",
  "summary": {
    "total_functions": 2588,
    "total_modules": 48,
    "marker_coverage_pct": 12.3,
    "heuristic_coverage_pct": 80.5,
    "evidence_coverage_pct": 8.1,
    "error_test_pct": 6.4,
    "test_file_count": 106,
    "total_it_count": 847
  },
  "categories": {
    "rendering": { "modules": [...], "coverage_pct": 81.2, "grade": "C+" },
    ...
  },
  "modules": {
    "light": {
      "name": "light",
      "category": "rendering",
      "tier": 1,
      "function_count": 45,
      "marker_covered": 0,
      "heuristic_covered": 32,
      "evidence_count": 0,
      "error_test_count": 2,
      "grade": "C-",
      "score": 4.2,
      "warnings": ["No visual evidence for light rendering", "0% marker coverage"],
      "functions": [...]
    }
  },
  "worst_modules": ["math", "light", "network", "postfx"],
  "uncovered_functions": [...]
}
```

---

## Integration with CI

```yaml
# .github/workflows/test-analytics.yml (future)
- name: Run test analytics
  run: |
    python tools/audit/test_analytics.py --json
    python tools/audit/test_analytics.py --trend   # fails if marker% decreased
    
- name: Upload analytics report
  uses: actions/upload-artifact@v3
  with:
    name: test-analytics-report
    path: |
      docs/quality/test_analytics.html
      docs/logs/test_analytics.json
```

---

## Maintenance

- **Frequency**: Run after any test file changes or `gen_lua_api_data.py` run
- **Output location**: `docs/quality/test_analytics.html` (browsable), `docs/logs/test_analytics.json` (git-tracked for trend)
- **Single source of truth**: Combines existing `test_coverage.py` and new `lua_api_test_coverage.py` — those tools become data sources; this is the report tool
- **Fast run**: Py-only, no Cargo build required, target <5s for full report
