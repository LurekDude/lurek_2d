# API Data Pipeline Analysis

## Current State

### Documented Pipeline (00-architecture.md, 02-intellisense-design.md)

The docs describe a data pipeline:

```
src/lua_api/*.rs  →  tools/generate-api-data.ts  →  data/*.json  →  providers
    (/// doc comments)   (parser script)           (IDE-ready data)   (IntelliSense)
```

Generated JSON files:
- `data/api-completions.json` — CompletionItem arrays per namespace
- `data/api-signatures.json` — SignatureInformation per function
- `data/api-hover.json` — Markdown hover content per function
- `data/api-enums.json` — Enum value sets for validation

### Actual Pipeline

The implementation uses `services/apiData.ts` (~800 lines) which contains **hardcoded API data**:
- ApiFunction, ApiModule, ApiEnum interfaces
- 10+ enum types defined inline (DrawMode, BodyType, BlendMode, etc.)
- 8 callback signatures defined inline
- No external JSON files loaded
- No generation script exists in the extension

Meanwhile, the **engine repo** has Python scripts that DO generate API data:
- `tools/gen_api_data.py` → `docs/api_data.json`
- `tools/gen_lua_api.py` → `docs/API/lua_api_reference_generated.md`
- `tools/gen_docs_lua.py` → `docs/lua-api.md` (from api_data.json)

---

## Gap Analysis

| Aspect | Documented | Actual | Impact |
|---|---|---|---|
| Data source | `///` doc comments from Rust | Hardcoded in TypeScript | API changes require manual TypeScript updates |
| Generation tool | tools/generate-api-data.ts | Does not exist | No automation |
| Output format | 4 JSON files in data/ | Inline objects in apiData.ts | Cannot be regenerated |
| Sync mechanism | Run script after API changes | Manual editing | Drift inevitable |
| Coverage | "729/1523 functions (48%)" | Unknown actual coverage | Hard to measure |

---

## Improvement Ideas

### 1. Build the Generation Pipeline

**Most impactful improvement**. Create the documented pipeline:

```
src/lua_api/*.rs  →  tools/gen_api_data.py  →  data/api_data.json  →  apiData.ts loads it
```

**Steps**:
1. The engine already generates `docs/api_data.json` via `tools/gen_api_data.py`
2. Copy or symlink `docs/api_data.json` → `vscode-extension/data/api_data.json`
3. Modify `apiData.ts` to load and parse the JSON file at activation
4. Remove hardcoded API definitions from `apiData.ts`
5. Add a VS Code command: `lurek.api.regenerate` → runs gen_api_data.py → reloads

**Benefit**: All 1523 functions automatically available in IntelliSense. Zero manual sync.

### 2. api_data.json Format Alignment

Verify that the existing `docs/api_data.json` contains all fields needed by providers:

| Provider Needs | api_data.json Has? | Action |
|---|---|---|
| Completion text | Function names | ✅ Should be present |
| Completion detail | Return type | ✅ Should be present |
| Hover markdown | Description + params | ✅ Should be present |
| Signature params | Parameter list | ✅ Should be present |
| Enum values | Enum sets | ❓ Check if gen_api_data.py extracts enums |
| Deprecation | Deprecated flag | ❓ Check format |
| Code examples | Examples | ❓ May need enrichment |

### 3. Incremental API Data Updates

**Problem**: Full regeneration is slow for large codebases.

**Improvement**:
- Hash each Rust source file
- Only re-extract from changed files
- Merge updated entries into existing JSON
- Run automatically on git pull / file change

### 4. API Coverage Dashboard

**Concept**: Visual report of API documentation coverage.

**Features**:
- Show % of lurek.* functions with docstrings
- Show % of parameters documented
- Show % of return types documented
- Highlight undocumented functions
- Link each gap to the source file for easy fixing

**Implementation**: Already partially exists as `lurek.apiCoverage` command.

### 5. Data Validation

**Improvement**: Validate api_data.json on load:
- Check for missing required fields
- Check for stale entries (function removed from engine)
- Check for duplicate entries
- Validate parameter types against known types
- Report validation errors in output channel

### 6. Multi-Source Data Merge

**Concept**: Combine multiple data sources for richer IntelliSense:

| Source | Data |
|---|---|
| `///` doc comments | Function names, params, return types, descriptions |
| LuaCATS annotations | User-defined classes and types |
| Runtime type inference | Actual types from running code |
| `api_data.json` | Generated comprehensive API data |
| `data/snippets.json` | Code snippet templates |

Merge strategy: `api_data.json` as base → enrich with LuaCATS → enrich with runtime inference.

### 7. Version-Aware API Data

**Problem**: API data may differ between engine versions.

**Improvement**:
- Include engine version in api_data.json
- Detect engine version from Cargo.toml in workspace
- Warn if api_data.json version doesn't match installed engine
- Support downloading correct api_data.json for the installed version

### 8. Snippets File Generation

**Currently missing**: `data/snippets.json` referenced in package2.json but doesn't exist.

**Action**: Generate from the 12 pattern library snippets documented in `08-intellisense-enhanced.md`:
- Class boilerplate, State machine, Event emitter, Object pool
- Component system, Timer utilities, Tween chain, FSM
- Signal/slot, Grid utilities, Stack/queue, Camera follow

### 9. Luna Library API Data

**Gap**: library/ modules (battle, crafting, dialog, etc.) are not part of the API data pipeline.

**Improvement**:
- Parse library/ Lua files for function definitions
- Extract LuaCATS annotations from library modules
- Include library APIs in IntelliSense
- Separate namespace: `library.combat.*`, `library.dialog.*`, etc.
