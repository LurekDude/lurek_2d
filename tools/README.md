# Lurek2D Tools Directory

Permanent CLI scripts for the Lurek2D engine pipeline, organised by category.
Every subfolder has its own `README.md` with the full script list and usage examples.

## Policy: Permanent vs Temporary Scripts

| Location                  | For                                                               |
| ------------------------- | ----------------------------------------------------------------- |
| `tools/<category>/`       | Permanent CLI utilities — reusable by any agent, CI, or developer |
| `work/{session}/scripts/` | One-off or session-scoped scripts — archived at session end       |

**Rule**: Do NOT create `_*.py` or one-off helper scripts in `tools/`. Temporary scripts
go under `work/{session}/scripts/` and are archived at session end.

---

## Subfolders

| Folder                                  | Purpose                                                                    | Script Count |
| --------------------------------------- | -------------------------------------------------------------------------- | ------------ |
| [`tools/docs/`](docs/README.md)         | Documentation generators — produce `docs/API/`, `docs/logs/`, `docs/wiki/` | 15           |
| [`tools/audit/`](audit/README.md)       | Quality auditing, coverage analytics, gap reports                          | 19           |
| [`tools/fix/`](fix/README.md)           | Code fixers and docstring improvers                                        | 14           |
| [`tools/validate/`](validate/README.md) | Schema and structure validators (exit 1 on failure)                        | 5            |
| [`tools/dist/`](dist/README.md)         | Build, package, and install scripts                                        | 7            |
| [`tools/github/`](github/README.md)     | GitHub project management automation                                       | 1            |
| [`tools/demos/`](demos/)                | Demo folder management and screenshot generation                           | 2            |
| [`tools/ui/`](ui/README.md)             | UI layout tooling — render TOML layout files to PNG wireframe previews     | 1            |
| [`tools/dev/`](dev/README.md)           | Dev helper scripts                                                         | 1            |

---

## Pipeline Orchestrator

```powershell
# Run the full documentation pipeline (all gen_* + coverage steps)
python tools/gen_all_docs.py
```

`gen_all_docs.py` lives at the tools root and calls scripts from `tools/docs/`
and `tools/audit/` in the correct dependency order. Produces:
- `docs/logs/rust_api_data.json` — raw Rust API metadata
- `docs/logs/lua_api_data.json` — raw Lua API metadata
- `docs/API/lurek.lua` — LuaCATS type stubs for IDE
- `docs/API/lua-api.md` — human-readable Lua API reference
- `docs/API/rust-api.md` — human-readable Rust API reference
- `docs/wiki/API-Reference.md` — game-developer cheatsheet
- `docs/logs/doc_coverage.json` — docstring coverage metrics
- `docs/logs/test_coverage.json` — test coverage metrics
- `docs/tests/test_docs_rust.md` — Rust test catalog
- `docs/tests/test_docs_lua.md` — Lua test catalog
- `docs/API/coverage_gaps.md` — Rust→Lua coverage gap report

---

## Complete Script Reference

### Documentation Generators (`tools/docs/`)

**Data layer** — produce machine-readable JSON from source:

| Script                 | Reads              | Produces                       | Args                    |
| ---------------------- | ------------------ | ------------------------------ | ----------------------- |
| `gen_rust_api_data.py` | `src/**/*.rs`      | `docs/logs/rust_api_data.json` | `--output`              |
| `gen_lua_api_data.py`  | `src/lua_api/*.rs` | `docs/logs/lua_api_data.json`  | `--output`, `--verbose` |

**Reference generators** — produce human-readable docs from JSON:

| Script                   | Reads                | Produces                             | Args                           |
| ------------------------ | -------------------- | ------------------------------------ | ------------------------------ |
| `gen_docs_lua.py`        | `lua_api_data.json`  | `docs/API/lua-api.md`                | —                              |
| `gen_docs_rust.py`       | `rust_api_data.json` | `docs/API/rust-api.md`               | —                              |
| `gen_luadoc.py`          | `lua_api_data.json`  | `docs/API/lurek.lua` (IDE stubs)     | —                              |
| `gen_wiki_api.py`        | `lua_api_data.json`  | `docs/wiki/API-Reference.md`         | —                              |
| `gen_lib_docs.py`        | `content/library/`   | `docs/API/lib-api.md`                | —                              |
| `gen_engine_docs.py`     | `src/` structure     | `docs/API/` engine docs              | —                              |
| `gen_lua_dev_docs.py`    | `lua_api_data.json`  | `docs/API/` dev docs                 | —                              |
| `gen_lua_library_api.py` | `content/library/`   | LuaCATS stubs for libs               | —                              |
| `gen_test_docs.py`       | `tests/`             | `docs/tests/test_docs_{rust,lua}.md` | `--mode rust\|lua`, `--output` |

**Legacy/analysis** — standalone reference tools:

| Script                    | Purpose                                             | Args                                                  |
| ------------------------- | --------------------------------------------------- | ----------------------------------------------------- |
| `gen_lua_api.py`          | Original Lua API scanner (reads `@param`/`@return`) | `--check` (coverage check)                            |
| `collect_docs.py`         | Rich API doc collector with missing-doc report      | `--report-missing`, `--suggest`, `--json`, `--output` |
| `gen_lua_api_skeleton.py` | Generate `src/lua_api/*_api.rs` skeleton stubs      | `--module NAME`, `--all`, `--dry-run`                 |

### Quality Auditing (`tools/audit/`)

**Master dashboards** — aggregate multiple sub-tools:

| Script              | Purpose                                   | Sub-tools called                                              | Args                                |
| ------------------- | ----------------------------------------- | ------------------------------------------------------------- | ----------------------------------- |
| `quality_report.py` | Overall quality dashboard (PASS/FAIL)     | `doc_audit`, `test_coverage`, `module_audit`, `validate_game` | `--json`, `--output`                |
| `doc_audit.py`      | Documentation audit (Rust + Lua combined) | `collect_docs`, `gen_lua_api_data`                            | `--json`, `--output`, `--threshold` |

**Docstring coverage** — measure and report docstring completeness:

| Script               | Purpose                                      | Output                           | Args                                                                  |
| -------------------- | -------------------------------------------- | -------------------------------- | --------------------------------------------------------------------- |
| `doc_coverage.py`    | Rust + Lua `///` docstring coverage metrics  | `docs/logs/doc_coverage.json`    | `--report-missing`, `--json`, `--module`, `--lua-only`, `--rust-only` |
| `docstring_audit.py` | Per-file Lua API docstring quality audit     | `docs/logs/docstring_audit.json` | `--json`, `--output`                                                  |
| `count_gaps.py`      | Count missing-doc items per `lurek.*` module | stdout                           | —                                                                     |

**Test coverage** — measure test completeness:

| Script                      | Purpose                                                          | Output                                         | Args                                                                   |
| --------------------------- | ---------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------- |
| `test_coverage.py`          | Cross-reference `pub` items vs test files                        | `docs/logs/test_coverage.json`                 | `--json`, `--suggest`, `--module`, `--threshold`                       |
| `lua_api_test_coverage.py`  | Lua API test coverage (via `@covers` markers)                    | `docs/logs/lua_api_test_coverage.json`         | `--strict`, `--json`, `--module`, `--suggest`, `--report`, `--orphans` |
| `unit_test_api_coverage.py` | Unit test API coverage metrics                                   | stdout                                         | —                                                                      |
| `example_coverage.py`       | Cross-reference `content/examples/` vs Lua API; exits 1 on gaps  | stdout / JSON                                  | `--module`, `--missing`, `--json`, `--report`                          |
| `example_add_missing.py`    | Append stub blocks for every uncovered API item to example files | patches `.lua`                                 | `--module`, `--dry-run`, `--report`, `--verbose`                       |
| `integration_coverage.py`   | Integration test module-pair heat map                            | stdout / `docs/logs/integration_coverage.json` | `--json`, `--output`                                                   |

**Module quality** — end-to-end module audits:

| Script                 | Purpose                                                           | Output                     | Args                                                               |
| ---------------------- | ----------------------------------------------------------------- | -------------------------- | ------------------------------------------------------------------ |
| `audit_module.py`      | 12-phase module quality audit (PASS/WARN/ERROR)                   | `docs/quality/<module>.md` | `NAME`, `--all`, `--tier N`, `--json`, `--docs-quality`            |
| `validate_agent_md.py` | Validate merged docs/specs module references (legacy script name) | stdout / JSON              | `--module`, `--all`, `--scaffold`, `--write`, `--strict`, `--json` |
| `module_audit.py`      | Module restructuring & reference audit                            | stdout / JSON              | `--json`, `--output`                                               |

**Specialised audits**:

| Script                 | Purpose                                          | Output                      |
| ---------------------- | ------------------------------------------------ | --------------------------- |
| `gen_coverage_gaps.py` | Rust→Lua API coverage gap report                 | `docs/API/coverage_gaps.md` |
| `golden_test.py`       | Deterministic output diff tests                  | stdout / JSON               |
| `stress_report.py`     | Stress test timing report                        | stdout / JSON               |
| `test_analytics.py`    | Test execution trend analysis                    | stdout                      |
| `parse_test_log.py`    | Parse Rust test execution logs (internal helper) | parsed data                 |

### Validators (`tools/validate/`)

All validators exit 0 on pass, 1 on failure.

| Script                        | Purpose                                                      | Args                                                      |
| ----------------------------- | ------------------------------------------------------------ | --------------------------------------------------------- |
| `cag_validate.py`             | Validate `.github/` CAG files (agents, skills, prompts)      | `--type agent\|skill\|prompt\|instruction`, `--file PATH` |
| `validate_lua_api.py`         | Validate `src/lua_api/*_api.rs` against SKILL.md contract    | `FILE_OR_DIR`, `--errors-only`                            |
| `validate_module_coverage.py` | Ensure every `src/` module has a spec and no legacy AGENT.md | `--fix-readme`                                            |
| `validate_game.py`            | Validate game/demo directory structure                       | `PATH`, `--all-examples`, `--json`, `--output`            |
| `check_callbacks.py`          | Verify gen_docs_lua callback output (internal)               | —                                                         |

### Code Fixers (`tools/fix/`)

> **WARNING**: These scripts modify files in-place. Always use `--dry-run` first.

**Docstring fixers** — add or improve `///` documentation:

| Script                       | Purpose                                                      | Args                       |
| ---------------------------- | ------------------------------------------------------------ | -------------------------- |
| `add_lua_docstrings.py`      | Interactive wizard: add missing `///` stubs                  | `--module NAME`            |
| `add_lua_docstrings_auto.py` | Auto-generate `///` stubs non-interactively                  | `--dry-run`, `--file FILE` |
| `improve_lua_docstrings.py`  | Upgrade low-quality stub comments                            | —                          |
| `fix_docstrings.py`          | Auto-fill `# Parameters`/`# Returns`/`# Fields`/`# Variants` | `--dry-run`                |
| `docstring_fix.py`           | Apply fixes from `docstring_audit.json`                      | `--dry-run`                |

**Example improvers** — enhance code examples in docstrings:

| Script                  | Purpose                       | Args |
| ----------------------- | ----------------------------- | ---- |
| `expand_examples.py`    | Expand code example blocks    | —    |
| `format_examples.py`    | Format code examples          | —    |
| `improve_examples.py`   | Improve example quality       | —    |
| `uncomment_examples.py` | Uncomment code example blocks | —    |

**Other fixers**:

| Script                              | Purpose                                            | Args |
| ----------------------------------- | -------------------------------------------------- | ---- |
| `add_test_markers.py`               | Add `@covers` test markers                         | —    |
| `find_typed_params.py`              | Discover params with explicit Lua type annotations | —    |
| `fix_type_stub_vars.py`             | Fix type stub variable declarations                | —    |
| `fix_typeof_args.py`                | Fix typeof() argument calls                        | —    |
| `strip_instance_method_comments.py` | Remove instance method doc comments                | —    |

### Build & Distribution (`tools/dist/`)

| Script          | Type       | Purpose                                                 | Args                    |
| --------------- | ---------- | ------------------------------------------------------- | ----------------------- |
| `dist.ps1`      | PowerShell | Windows release package → `dist/` + `.zip`              | `-OutDir`, `-SkipBuild` |
| `dist.sh`       | Bash       | Linux/macOS release package → `dist/` + `.tar.gz`       | —                       |
| `install.ps1`   | PowerShell | Windows local install (`%USERPROFILE%\bin`)             | `--uninstall`           |
| `install.sh`    | Bash       | Linux/macOS local install (`/usr/local/bin`)            | —                       |
| `installer.nsi` | NSIS       | Windows GUI installer                                   | —                       |
| `pack.ps1`      | PowerShell | Pack game folder into `.lurek` archive                  | `<folder> <output>`     |
| `pack.py`       | Python     | Pack game folder into `.lurek` archive (cross-platform) | `<folder> <output>`     |

### GitHub (`tools/github/`)

| Script                      | Purpose                            | Args                                       |
| --------------------------- | ---------------------------------- | ------------------------------------------ |
| `ideas_to_github_issues.py` | Create GitHub issues from `ideas/` | `--repo`, `--token`, `--path`, `--dry-run` |

### Demo Management (`tools/demos/`)

| Script                          | Purpose                            |
| ------------------------------- | ---------------------------------- |
| `demos/organize_demos.py`       | Demo folder organisation/cleanup   |
| `demos/gen_demo_screenshots.py` | Generate demo screenshots for docs |

### Dev Helpers (`tools/dev/`)

| Script                 | Purpose                             |
| ---------------------- | ----------------------------------- |
| `dev/test_fix_loop.py` | Dev helper: test-fix iteration loop |

### Root-level scripts

| Script            | Status                             | Purpose                                  |
| ----------------- | ---------------------------------- | ---------------------------------------- |
| `gen_all_docs.py` | **Active** — Pipeline orchestrator | Runs all doc + coverage scripts in order |

---

## Tool Relationship Map

### Dependencies (A calls B)

```
gen_all_docs.py
├── gen_rust_api_data.py  → docs/logs/rust_api_data.json
├── gen_lua_api_data.py   → docs/logs/lua_api_data.json
├── gen_luadoc.py         ← reads lua_api_data.json
├── gen_docs_lua.py       ← reads lua_api_data.json
├── gen_docs_rust.py      ← reads rust_api_data.json
├── gen_wiki_api.py       ← reads lua_api_data.json
├── doc_coverage.py       → docs/logs/doc_coverage.json
├── test_coverage.py      → docs/logs/test_coverage.json
├── gen_test_docs.py      → docs/tests/
└── gen_coverage_gaps.py  → docs/API/coverage_gaps.md

quality_report.py
├── doc_audit.py
│   ├── collect_docs.py   (Rust docs)
│   └── gen_lua_api_data.py (Lua API docs)
├── test_coverage.py
├── module_audit.py
└── validate_game.py

audit_module.py           (standalone, reads source directly)
validate_agent_md.py      (standalone, reads docs/specs/*.md module references)
docstring_audit.py        (standalone, reads lua_api source)
```

### Overlap-Free Ownership

| Domain                   | Primary Tool                  | Complementary Tool           | Relationship                                                                            |
| ------------------------ | ----------------------------- | ---------------------------- | --------------------------------------------------------------------------------------- |
| Rust `///` coverage      | `doc_coverage.py`             | `collect_docs.py`            | `doc_coverage` = metrics; `collect_docs` = rich reference + missing list                |
| Lua API docstrings       | `docstring_audit.py`          | `doc_coverage.py --lua-only` | `docstring_audit` = per-function quality; `doc_coverage` = aggregate %                  |
| Test coverage (Rust)     | `test_coverage.py`            | `unit_test_api_coverage.py`  | `test_coverage` = heuristic cross-ref; `unit_test_api_coverage` = unit-level            |
| Test coverage (Lua)      | `lua_api_test_coverage.py`    | `test_coverage.py`           | `lua_api_test_coverage` = precise `@covers`; `test_coverage` = broad heuristic          |
| Module reference quality | `validate_agent_md.py`        | `audit_module.py`            | `validate_agent_md` = merged spec structure only; `audit_module` = broader module audit |
| Module structure         | `validate_module_coverage.py` | `module_audit.py`            | `validate_module_coverage` = file existence; `module_audit` = restructuring ideas       |

---

## Quality Pipeline — When to Run What

### After every code change (pre-commit)

```powershell
cargo test && cargo clippy -- -D warnings
```

### After adding/changing Lua API bindings

```powershell
python tools/gen_all_docs.py                          # regenerate all docs
python tools/validate/validate_lua_api.py src/lua_api/ # validate bindings
python tools/audit/docstring_audit.py                  # check docstring quality
```

### After adding/changing a module

```powershell
python tools/validate/validate_module_coverage.py     # merged specs exist and AGENT.md is gone?
python tools/audit/validate_agent_md.py --module NAME # merged spec structure ok?
python tools/audit/audit_module.py NAME               # full 12-phase audit
```

### Weekly quality check

```powershell
python tools/audit/quality_report.py                  # master dashboard
python tools/audit/audit_module.py --all --docs-quality  # all module reports
python tools/audit/lua_api_test_coverage.py --report  # Lua test coverage
```

### After editing `.github/` CAG files

```powershell
python tools/validate/cag_validate.py                 # validate CAG layer
```

---

## Adding a New Tool

1. Choose the right subfolder (`docs/`, `audit/`, `fix/`, `validate/`, `dist/`, or `github/`)
2. Add a module-level docstring with:
   - One-sentence purpose
   - Usage examples matching the new path
3. Update the subfolder's `README.md` table
4. Update this `tools/README.md` table
5. If the tool is invoked from `gen_all_docs.py`, add it to the `SCRIPTS` list there
6. If it needs a VS Code task, add an entry in `.vscode/tasks.json`
7. If it's a quality tool, consider adding it to the `quality-pipeline` skill
