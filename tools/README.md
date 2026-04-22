# Lurek2D Tools Directory

Permanent CLI scripts for the Lurek2D engine pipeline, organised by category.
Every subfolder has its own `README.md` with the full script list and usage examples.

## Policy: Permanent vs Temporary Scripts

| Location                  | For                                                               |
| ------------------------- | ----------------------------------------------------------------- |
| `tools/<category>/`       | Permanent CLI utilities â€” reusable by any agent, CI, or developer |
| `work/{session}/scripts/` | One-off or session-scoped scripts â€” archived at session end       |

**Rule**: Do NOT create `_*.py` or one-off helper scripts in `tools/`. Temporary scripts
go under `work/{session}/scripts/` and are archived at session end.

---

## Subfolders

| Folder                                  | Purpose                                                                    | Script Count |
| --------------------------------------- | -------------------------------------------------------------------------- | ------------ |
| [`tools/docs/`](docs/README.md)         | Documentation generators â€” produce `docs/reports/`, `logs/`, `wiki/` | 15           |
| [`tools/audit/`](audit/README.md)       | Quality auditing, coverage analytics, gap reports                          | 29           |
| [`tools/fix/`](fix/README.md)           | Code fixers and docstring improvers                                        | 9            |
| [`tools/validate/`](validate/README.md) | Schema and structure validators (exit 1 on failure)                        | 7            |
| [`tools/dist/`](dist/README.md)         | Build, package, and install scripts                                        | 7            |
| [`tools/github/`](github/README.md)     | GitHub project management automation                                       | 1            |
| [`tools/demos/`](demos/README.md)       | Demo folder management, screenshot generation, smoke testing               | 3            |
| [`tools/ui/`](ui/README.md)             | UI layout tooling â€” render TOML layout files to PNG wireframe previews     | 3            |
| [`tools/dev/`](dev/README.md)           | Dev helper scripts                                                         | 2            |
| [`tools/mods/`](mods/README.md)         | Mod scaffolding helpers (`lurek-mod` workflow)                              | 1            |
| [`tools/assets/`](assets/README.md)     | Notes on engine asset placement (no scripts)                               | 0            |

---

## Pipeline Orchestrator

```powershell
# Run the full documentation pipeline (all gen_* + coverage steps)
python tools/gen_all_docs.py
```

`gen_all_docs.py` lives at the tools root and calls scripts from `tools/docs/`
and `tools/audit/` in the correct dependency order. Produces:
- `logs/data/rust_api_data.json` â€” raw Rust API metadata
- `logs/data/lua_api_data.json` â€” raw Lua API metadata
- `docs/lurek.lua` â€” LuaCATS type stubs for IDE
- `docs/api/lurek.md` â€” human-readable Lua API reference
- `docs/api/rust.md` â€” human-readable Rust API reference
- `wiki/API-Reference.md` â€” game-developer cheatsheet
- `logs/reports/doc_coverage.json` â€” docstring coverage metrics
- `logs/reports/test_coverage.json` â€” test coverage metrics
- `docs/reports/test_docs_rust.md` â€” Rust test catalog
- `docs/reports/test_docs_lua.md` â€” Lua test catalog
- `logs/reports/coverage_gaps.md` â€” Rustâ†’Lua coverage gap report

---

## Complete Script Reference

### Documentation Generators (`tools/docs/`)

**Data layer** â€” produce machine-readable JSON from source:

| Script                 | Reads              | Produces                       | Args                    |
| ---------------------- | ------------------ | ------------------------------ | ----------------------- |
| `gen_rust_api_data.py` | `src/**/*.rs`      | `logs/data/rust_api_data.json` | `--output`              |
| `gen_lua_api_data.py`  | `src/lua_api/*.rs` | `logs/data/lua_api_data.json`  | `--output`, `--verbose` |

**Reference generators** â€” produce human-readable docs from JSON:

| Script                   | Reads                | Produces                             | Args                           |
| ------------------------ | -------------------- | ------------------------------------ | ------------------------------ |
| `gen_docs_lua.py`        | `lua_api_data.json`  | `docs/api/lurek.md`                | â€”                              |
| `gen_docs_rust.py`       | `rust_api_data.json` | `docs/api/rust.md`               | â€”                              |
| `gen_luadoc.py`          | `lua_api_data.json`  | `docs/lurek.lua` (IDE stubs)     | â€”                              |
| `gen_wiki_api.py`        | `lua_api_data.json`  | `wiki/API-Reference.md`         | â€”                              |
| `gen_lib_docs.py`        | `library/`   | `docs/reports/lib-api.md`                | â€”                              |
| `gen_engine_docs.py`     | `src/` structure     | `docs/reports/` engine docs              | â€”                              |
| `gen_lua_dev_docs.py`    | `lua_api_data.json`  | `docs/reports/` dev docs                 | â€”                              |
| `gen_lua_library_api.py` | `library/`   | LuaCATS stubs for libs               | â€”                              |
| `gen_test_docs.py`       | `tests/`             | `docs/reports/test_docs_{rust,lua}.md` | `--mode rust\|lua`, `--output` |

**Legacy/analysis** â€” standalone reference tools:

| Script                    | Purpose                                             | Args                                                  |
| ------------------------- | --------------------------------------------------- | ----------------------------------------------------- |
| `gen_lua_api.py`          | Original Lua API scanner (reads `@param`/`@return`) | `--check` (coverage check)                            |
| `collect_docs.py`         | Rich API doc collector with missing-doc report      | `--report-missing`, `--suggest`, `--json`, `--output` |

### Quality Auditing (`tools/audit/`)

**Master dashboards** â€” aggregate multiple sub-tools:

| Script              | Purpose                                   | Sub-tools called                                              | Args                                |
| ------------------- | ----------------------------------------- | ------------------------------------------------------------- | ----------------------------------- |
| `quality_report.py` | Overall quality dashboard (PASS/FAIL)     | `doc_audit`, `test_coverage`, `module_audit`, `validate_game` | `--json`, `--output`                |
| `doc_audit.py`      | Documentation audit (Rust + Lua combined) | `collect_docs`, `gen_lua_api_data`                            | `--json`, `--output`, `--threshold` |

**Docstring coverage** â€” measure and report docstring completeness:

| Script               | Purpose                                      | Output                           | Args                                                                  |
| -------------------- | -------------------------------------------- | -------------------------------- | --------------------------------------------------------------------- |
| `doc_coverage.py`    | Rust + Lua `///` docstring coverage metrics  | `logs/reports/doc_coverage.json`    | `--report-missing`, `--json`, `--module`, `--lua-only`, `--rust-only` |
| `docstring_audit.py` | Per-file Lua API docstring quality audit     | `logs/data/docstring_audit.json` | `--json`, `--output`                                                  |
| `count_gaps.py`      | Count missing-doc items per `lurek.*` module | stdout                           | â€”                                                                     |

**Test coverage** â€” measure test completeness:

| Script                      | Purpose                                                          | Output                                         | Args                                                                   |
| --------------------------- | ---------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------- |
| `test_coverage.py`          | Cross-reference `pub` items vs test files                        | `logs/reports/test_coverage.json`                 | `--json`, `--suggest`, `--module`, `--threshold`                       |
| `lua_api_test_coverage.py`  | Lua API test coverage (via `@covers` markers)                    | `logs/reports/lua_api_test_coverage.json`         | `--strict`, `--json`, `--module`, `--suggest`, `--report`, `--orphans` |
| `unit_test_api_coverage.py` | Unit test API coverage metrics                                   | stdout                                         | â€”                                                                      |
| `example_coverage.py`       | Cross-reference `content/examples/` vs Lua API; exits 1 on gaps  | stdout / JSON                                  | `--module`, `--missing`, `--json`, `--report`                          |
| `example_add_missing.py`    | Append stub blocks for every uncovered API item to example files | patches `.lua`                                 | `--module`, `--dry-run`, `--report`, `--verbose`                       |
| `integration_coverage.py`   | Integration test module-pair heat map                            | stdout / `logs/integration_coverage.json` | `--json`, `--output`                                                   |

**Module quality** â€” end-to-end module audits:

| Script                 | Purpose                                                           | Output                     | Args                                                               |
| ---------------------- | ----------------------------------------------------------------- | -------------------------- | ------------------------------------------------------------------ |
| `audit_module.py`      | 12-phase module quality audit (PASS/WARN/ERROR)                   | `logs/quality/<module>.md` | `NAME`, `--all`, `--tier N`, `--json`, `--docs-quality`            |

**Specialised audits**:

| Script                 | Purpose                                          | Output                      |
| ---------------------- | ------------------------------------------------ | --------------------------- |
| `gen_coverage_gaps.py`     | Rustâ†’Lua API coverage gap report                     | `logs/reports/coverage_gaps.md` |
| `golden_test.py`           | Deterministic output diff tests                      | stdout / JSON               |
| `stress_report.py`         | Stress test timing report                            | stdout / JSON               |
| `test_analytics.py`        | Test execution trend analysis                        | stdout                      |
| `parse_test_log.py`        | Parse Rust test execution logs (internal helper)     | parsed data                 |
| `strict_api_check.py`      | Validate all `lurek.*` API stubs in examples         | stdout                      |
| `strict_api_check_math.py` | Validate math-module API stubs in examples           | stdout                      |
| `wiki_coverage.py`         | Cross-reference wiki/ vs src/ modules & libs    | stdout / JSON               |
| `tool_registry_audit.py`   | Self-audit: verify tools registry internal consistency | stdout / JSON               |

### Validators (`tools/validate/`)

All validators exit 0 on pass, 1 on failure.

| Script                        | Purpose                                                      | Args                                                      |
| ----------------------------- | ------------------------------------------------------------ | --------------------------------------------------------- |
| `cag_validate.py`             | Validate `.github/` CAG files (agents, skills, prompts)      | `--type agent\|skill\|prompt\|instruction`, `--file PATH` |
| `validate_lua_api.py`         | Validate `src/lua_api/*_api.rs` against SKILL.md contract    | `FILE_OR_DIR`, `--errors-only`                            |
| `validate_module_coverage.py` | Ensure every `src/` module has a spec and no legacy AGENT.md | `--fix-readme`                                            |
| `validate_game.py`            | Validate game/demo directory structure                       | `PATH`, `--all-examples`, `--json`, `--output`            |
| `validate_changelog.py`       | Validate CHANGELOG structure: versions, ordering, dates      | `--strict`, `--format text\|json`                         |
| `validate_library.py`         | Validate library/ entries: required files, LDoc tags | `--library NAME`, `--strict`, `--format text\|json`       |
| `check_callbacks.py`          | Verify gen_docs_lua callback output (internal)               | â€”                                                         |

### Code Fixers (`tools/fix/`)

> **WARNING**: These scripts modify files in-place. Always use `--dry-run` first.

**Docstring fixers** â€” add or improve `///` documentation:

| Script                       | Purpose                                                      | Args                       |
| ---------------------------- | ------------------------------------------------------------ | -------------------------- |
| `add_lua_docstrings.py`      | Interactive wizard: add missing `///` stubs                  | `--module NAME`            |
| `add_lua_docstrings_auto.py` | Auto-generate `///` stubs non-interactively                  | `--dry-run`, `--file FILE` |
| `improve_lua_docstrings.py`  | Upgrade low-quality stub comments                            | â€”                          |
| `fix_docstrings.py`          | Auto-fill `# Parameters`/`# Returns`/`# Fields`/`# Variants` | `--dry-run`                |
| `docstring_fix.py`           | Apply fixes from `docstring_audit.json`                      | `--dry-run`                |

**Example improvers** â€” enhance code examples in docstrings:

| Script                  | Purpose                       | Args |
| ----------------------- | ----------------------------- | ---- |
| `expand_examples.py`    | Expand code example blocks    | â€”    |
| `format_examples.py`    | Format code examples          | â€”    |
| `improve_examples.py`   | Improve example quality       | â€”    |

**Other fixers**:

| Script                              | Purpose                                            | Args |
| ----------------------------------- | -------------------------------------------------- | ---- |
| `add_test_markers.py`               | Add `@covers` test markers                         | â€”    |

### Build & Distribution (`tools/dist/`)

| Script          | Type       | Purpose                                                 | Args                    |
| --------------- | ---------- | ------------------------------------------------------- | ----------------------- |
| `dist.ps1`      | PowerShell | Windows release package â†’ `dist/` + `.zip`              | `-OutDir`, `-SkipBuild` |
| `dist.sh`       | Bash       | Linux/macOS release package â†’ `dist/` + `.tar.gz`       | â€”                       |
| `install.ps1`   | PowerShell | Windows local install (`%USERPROFILE%\bin`)             | `--uninstall`           |
| `install.sh`    | Bash       | Linux/macOS local install (`/usr/local/bin`)            | â€”                       |
| `installer.nsi` | NSIS       | Windows GUI installer                                   | â€”                       |
| `pack.ps1`      | PowerShell | Pack game folder into `.lurek` archive                  | `<folder> <output>`     |
| `pack.py`       | Python     | Pack game folder into `.lurek` archive (cross-platform) | `<folder> <output>`     |

### GitHub (`tools/github/`)

| Script                      | Purpose                            | Args                                       |
| --------------------------- | ---------------------------------- | ------------------------------------------ |
| `ideas_to_github_issues.py` | Create GitHub issues from `ideas/` | `--repo`, `--token`, `--path`, `--dry-run` |

### Demo Management (`tools/demos/`)

| Script                          | Purpose                            |
| ------------------------------- | ---------------------------------- |
| `demos/organize_demos.py`       | Demo folder organisation/cleanup              |
| `demos/gen_demo_screenshots.py` | Generate demo screenshots for docs            |
| `demos/smoke_sweep.py`          | Smoke-test all demos/examples for crash-free launch |

### Dev Helpers (`tools/dev/`)

| Script                 | Purpose                             |
| ---------------------- | ----------------------------------- |
| `dev/parallel_cargo.py` | Unified build/check/run/test/clippy/fmt/doc orchestration with bounded Rust test fan-out |
| `dev/test_fix_loop.py` | Dev helper: test-fix iteration loop |

### Root-level scripts

| Script            | Status                             | Purpose                                  |
| ----------------- | ---------------------------------- | ---------------------------------------- |
| `gen_all_docs.py` | **Active** â€” Pipeline orchestrator | Runs all doc + coverage scripts in order |

---

## Tool Relationship Map

### Dependencies (A calls B)

```
gen_all_docs.py
â”śâ”€â”€ gen_rust_api_data.py  â†’ logs/data/rust_api_data.json
â”śâ”€â”€ gen_lua_api_data.py   â†’ logs/data/lua_api_data.json
â”śâ”€â”€ gen_luadoc.py         â† reads lua_api_data.json
â”śâ”€â”€ gen_docs_lua.py       â† reads lua_api_data.json
â”śâ”€â”€ gen_docs_rust.py      â† reads rust_api_data.json
â”śâ”€â”€ gen_wiki_api.py       â† reads lua_api_data.json
â”śâ”€â”€ doc_coverage.py       â†’ logs/reports/doc_coverage.json
â”śâ”€â”€ test_coverage.py      â†’ logs/reports/test_coverage.json
â”śâ”€â”€ gen_test_docs.py      â†’ docs/reports/
â””â”€â”€ gen_coverage_gaps.py  â†’ logs/reports/coverage_gaps.md

quality_report.py
â”śâ”€â”€ doc_audit.py
â”‚   â”śâ”€â”€ collect_docs.py   (Rust docs)
â”‚   â””â”€â”€ gen_lua_api_data.py (Lua API docs)
â”śâ”€â”€ test_coverage.py
â””â”€â”€ validate_game.py

audit_module.py           (standalone, reads source directly)
docstring_audit.py        (standalone, reads lua_api source)
tool_registry_audit.py    (standalone, self-audit of tools/ registry)
wiki_coverage.py          (standalone, cross-refs wiki/ vs src/ modules)
```

### Overlap-Free Ownership

| Domain                   | Primary Tool                  | Complementary Tool           | Relationship                                                                            |
| ------------------------ | ----------------------------- | ---------------------------- | --------------------------------------------------------------------------------------- |
| Rust `///` coverage      | `doc_coverage.py`             | `collect_docs.py`            | `doc_coverage` = metrics; `collect_docs` = rich reference + missing list                |
| Lua API docstrings       | `docstring_audit.py`          | `doc_coverage.py --lua-only` | `docstring_audit` = per-function quality; `doc_coverage` = aggregate %                  |
| Test coverage (Rust)     | `test_coverage.py`            | `unit_test_api_coverage.py`  | `test_coverage` = heuristic cross-ref; `unit_test_api_coverage` = unit-level            |
| Test coverage (Lua)      | `lua_api_test_coverage.py`    | `test_coverage.py`           | `lua_api_test_coverage` = precise `@covers`; `test_coverage` = broad heuristic          |
| Module structure         | `validate_module_coverage.py` | â€”                            | Single tool: validates that every src/ module has a docs/specs/ file                    |
| CHANGELOG                | `validate_changelog.py`       | â€”                            | Structure, version ordering, dates                                                      |
| Library quality          | `validate_library.py`         | â€”                            | Required files, LDoc tags, return tables                                                |
| Wiki completeness        | `wiki_coverage.py`            | â€”                            | Cross-reference wiki pages vs src/ modules                                              |
| Tools registry           | `tool_registry_audit.py`      | â€”                            | Self-audit: READMEs, docstrings, paths                                                  |

---

## Quality Pipeline â€” When to Run What

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

### After editing `library/`

```powershell
python tools/validate/validate_library.py             # validate all libraries
python tools/validate/validate_library.py --library NAME --strict  # single library
python tools/docs/gen_lib_docs.py                     # regenerate library docs
```

### After editing `docs/CHANGELOG.md`

```powershell
python tools/validate/validate_changelog.py           # validate structure
python tools/validate/validate_changelog.py --strict   # treat warnings as errors
```

### After editing `tools/`

```powershell
python tools/audit/tool_registry_audit.py             # self-audit tools registry
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

---

## Discovery for Agents

AI agents working in this repo should pick a tool by **subfolder taxonomy first, script docstring second**. The taxonomy maps directly to intent:

| Intent                                                | Subfolder           |
| ----------------------------------------------------- | ------------------- |
| "Is this CAG / spec / contract well-formed?"          | `tools/validate/`   |
| "Measure quality / coverage / report gaps."           | `tools/audit/`      |
| "Modify source files in-place to fix something."      | `tools/fix/`        |
| "Regenerate generated documentation."                 | `tools/docs/`       |
| "Build, package, or install the engine binary."       | `tools/dist/`       |
| "Manage GitHub issues, milestones, or releases."      | `tools/github/`     |
| "Maintain `content/demos/` (folders, screenshots)."   | `tools/demos/`      |
| "Author or scaffold a `lurek-mod` plugin."            | `tools/mods/`       |
| "Render or fix `*.layout.toml` UI files."             | `tools/ui/`         |
| "Engine-developer helper (test-fix loop, etc)."       | `tools/dev/`        |

Workflow:
1. Classify the task into one of the rows above.
2. Open that subfolder's `README.md` and pick the script whose one-line description matches.
3. Read the script's module docstring (`python -c "import tools.subdir.script as m; print(m.__doc__)"` or just open the file) for full CLI flags.
4. If no script fits, check **Standalone utilities** below â€” a one-shot might already exist.

Validators always exit 1 on failure; auditors print metrics and return 0 unless `--strict` or `--threshold` is used; fixers default to in-place edits and should be invoked with `--dry-run` first when supported.

---

## Standalone utilities

Scripts kept in `tools/` that are not currently referenced by any `.github/` agent, skill, or prompt. They remain because they are ad-hoc one-shots, archived debug helpers, or have niche scopes.

| Script                                          | Kept because                                                              |
| ----------------------------------------------- | ------------------------------------------------------------------------- |
| `tools/audit/gen_coverage_gaps.py`              | Invoked via `gen_all_docs.py` orchestrator, not directly by agents.       |
| `tools/audit/golden_test.py`                    | Manual diff-debug helper for golden-file regressions.                     |
| `tools/audit/test_analytics.py`                 | Trend-only reporter; consumed by humans, not gates.                       |
| `tools/audit/unit_test_api_coverage.py`         | Niche metric; superset covered by `lua_api_test_coverage.py`.             |
| `tools/audit/parse_test_log.py`                 | Internal helper for `quality_report.py`.                                  |
| `tools/demos/organize_demos.py`                 | One-shot demos folder normaliser, run only when restructuring.            |
| `tools/dev/test_fix_loop.py`                    | Local dev convenience; not part of CI or any agent workflow.              |
| `tools/dist/pack.ps1`, `tools/dist/pack.py`     | Player-facing pack helpers, invoked from VS Code tasks not CAG.           |
| `tools/docs/gen_docs_rust.py`                   | Run via `gen_all_docs.py`; not directly invoked by agents.                |
| `tools/docs/gen_lua_dev_docs.py`                | Subset of `gen_all_docs.py` pipeline.                                     |
| `tools/docs/gen_lua_library_api.py`             | Run via `gen_lib_docs.py`; chained internally.                            |
| `tools/docs/gen_luadoc.py`                      | Chained from `gen_all_docs.py`; produces LuaCATS stubs.                   |
| `tools/docs/gen_rust_api_data.py`               | Chained from `gen_all_docs.py`; produces JSON intermediate.               |
| `tools/docs/gen_test_docs.py`                   | Chained from `gen_all_docs.py`.                                           |
| `tools/docs/gen_wiki.py`                        | Manual wiki-rebuild helper; superseded by `gen_wiki_api.py` for API page. |
| `tools/fix/add_lua_docstrings.py`               | Interactive â€” used by humans, not agents (auto variant is preferred).     |
| `tools/fix/improve_examples.py`                 | Manual content-quality helper.                                            |
| `tools/github/ideas_to_github_issues.py`        | One-shot â€” bulk-imports `ideas/` into Issues; rarely needed.              |
| `tools/mods/mod_init.py`                        | Modder-facing scaffolder; invoked by humans via VS Code task.             |
| `tools/validate/_cag_common.py`                 | Private helper module for CAG validators (not directly callable).         |


