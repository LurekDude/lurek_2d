# P7 Tools Inventory

Generated: walked 77 script(s) under `tools/`.

- Scripts without docstring/header: **0**
- Scripts unreferenced by any `.github/` artifact: **19**


## Per-script status

| Path | Doc? | Refs | Description |
|---|:--:|:--:|---|
| `tools/audit/annotate_tests.py` | ✅ | 1 | annotate_tests.py — Auto-insert @tests annotations into Lua unit test files. |
| `tools/audit/audit_module.py` | ✅ | 7 | audit_module.py — Lurek2D module quality audit tool. |
| `tools/audit/cag_coverage.py` | ✅ | 1 | cag_coverage.py — required-section coverage analytics for CAG files. |
| `tools/audit/cag_link_check.py` | ✅ | 1 | cag_link_check.py — broken-link checker for the CAG layer. |
| `tools/audit/cag_persona_matrix.py` | ✅ | 1 | cag_persona_matrix.py — persona ↔ agent value matrix. |
| `tools/audit/count_gaps.py` | ✅ | 1 | count_gaps.py — Count undocumented public API items per lurek.* module. |
| `tools/audit/doc_audit.py` | ✅ | 1 | doc_audit.py — Lurek2D unified documentation audit. |
| `tools/audit/doc_coverage.py` | ✅ | 8 | doc_coverage.py — Lurek2D documentation coverage analytics. |
| `tools/audit/docstring_audit.py` | ✅ | 1 | docstring_audit.py -- Audit Lurek2D Lua API docstrings for missing content. |
| `tools/audit/example_add_missing.py` | ✅ | 1 | Append stub sections to content/examples/ for uncovered lurek.* API items. |
| `tools/audit/example_coverage.py` | ✅ | 4 | Cross-reference content/examples/ scripts against the lurek.* Lua API. |
| `tools/audit/gen_coverage_gaps.py` | ✅ | 0 | gen_coverage_gaps.py — Generate an API gap report for Lurek2D. |
| `tools/audit/golden_test.py` | ✅ | 1 | golden_test.py — Lurek2D golden file comparison tests. |
| `tools/audit/integration_coverage.py` | ✅ | 2 | integration_coverage.py — Lurek2D integration test coverage analysis. |
| `tools/audit/lua_api_test_coverage.py` | ✅ | 2 | lua_api_test_coverage.py — Precise Lua API test coverage analysis. |
| `tools/audit/lua_evidence_golden_contract_audit.py` | ✅ | 4 | Audit Lua evidence and golden test contract compliance. |
| `tools/audit/lua_test_structure_audit.py` | ✅ | 3 | Audit and normalize Lua BDD test structure under tests/lua. |
| `tools/audit/module_audit.py` | ✅ | 0 | module_audit.py — Lurek2D module restructuring audit. |
| `tools/audit/parse_test_log.py` | ✅ | 1 | tools/audit/parse_test_log.py — Parse `cargo test` output into a structured summary. |
| `tools/audit/quality_report.py` | ✅ | 3 | quality_report.py — Lurek2D master quality report. |
| `tools/audit/stress_report.py` | ✅ | 1 | stress_report.py — Lurek2D stress test runner and reporter. |
| `tools/audit/test_analytics.py` | ✅ | 0 | test_analytics.py — Lurek2D comprehensive test analytics. |
| `tools/audit/test_coverage.py` | ✅ | 8 | test_coverage.py — Lurek2D test coverage analysis. |
| `tools/audit/unit_test_api_coverage.py` | ✅ | 1 | unit_test_api_coverage.py — Lurek2D unit-test API coverage analysis. |
| `tools/demos/gen_demo_screenshots.py` | ✅ | 2 | gen_demo_screenshots.py — Capture a screen.png for every Lurek2D demo. |
| `tools/demos/organize_demos.py` | ✅ | 0 | organize_demos.py — Three-in-one demos maintenance tool. |
| `tools/dev/test_fix_loop.py` | ✅ | 1 | tools/scripts/test_fix_loop.py — Agent-friendly test-run / fix / re-run loop. |
| `tools/dist/dist.ps1` | ✅ | 3 | Build and package Lurek2D for Windows distribution. |
| `tools/dist/dist.sh` | ✅ | 1 | dist.sh — Build and package Lurek2D for Linux / macOS distribution. |
| `tools/dist/install.ps1` | ✅ | 1 | Install or uninstall the Lurek2D engine locally on Windows. |
| `tools/dist/install.sh` | ✅ | 1 | install.sh — Install or uninstall Lurek2D on Linux / macOS |
| `tools/dist/pack.ps1` | ✅ | 0 | tools/pack.ps1 |
| `tools/dist/pack.py` | ✅ | 0 | tools/pack.py — Pack a Lurek2D game directory into a .lurek archive. |
| `tools/docs/collect_docs.py` | ✅ | 11 | collect_docs.py — Lurek2D rich structured API documentation collector. |
| `tools/docs/gen_docs_lua.py` | ✅ | 3 | gen_docs_lua.py -- Generate Lua API reference from docs/logs/lua_api_data.json. |
| `tools/docs/gen_docs_rust.py` | ✅ | 0 | gen_docs_rust.py — Generate compact inline Rust API reference from docs/logs/rust_api_data.json. |
| `tools/docs/gen_engine_docs.py` | ✅ | 1 | gen_engine_docs.py — Generate per-module documentation for Lurek2D Rust engine source. |
| `tools/docs/gen_lib_docs.py` | ✅ | 3 | gen_lib_docs.py — Generate Markdown API docs from Lurek2D library Lua files. |
| `tools/docs/gen_lua_api.py` | ✅ | 4 | gen_lua_api.py — Lurek2D Lua API parser library. |
| `tools/docs/gen_lua_api_data.py` | ✅ | 1 | gen_lua_api_data.py — Generate Lurek2D master API data file. |
| `tools/docs/gen_lua_api_skeleton.py` | ✅ | 1 | gen_lua_api_skeleton.py — Generate src/lua_api/<module>_api.rs skeleton files |
| `tools/docs/gen_lua_dev_docs.py` | ✅ | 0 | gen_lua_dev_docs.py — Generate Lua developer documentation from lua_api *.rs files. |
| `tools/docs/gen_lua_library_api.py` | ✅ | 0 | gen_lua_library_api.py — Generate API reference docs from Lurek2D Lua library files. |
| `tools/docs/gen_luadoc.py` | ✅ | 0 | gen_luadoc.py — Generate LuaCATS type-annotation stubs for the Lurek2D VS Code extension. |
| `tools/docs/gen_module_specs.py` | ✅ | 2 | Generate merged docs/specs/<module>.md files for top-level src modules. |
| `tools/docs/gen_rust_api_data.py` | ✅ | 1 | gen_rust_api_data.py — Generate Lurek2D master API data file. |
| `tools/docs/gen_test_docs.py` | ✅ | 1 | gen_test_docs.py — Generate human-readable test documentation for Lurek2D. |
| `tools/docs/gen_wiki.py` | ✅ | 1 | gen_wiki.py — Regenerate ALL Lurek2D wiki pages from source content. |
| `tools/docs/gen_wiki_api.py` | ✅ | 1 | gen_wiki_api.py — Generate docs/wiki/API-Reference.md from docs/logs/lua_api_data.json. |
| `tools/fix/add_lua_docstrings.py` | ✅ | 1 | add_lua_docstrings.py - Auto-generate /// docstrings from inline comments. |
| `tools/fix/add_lua_docstrings_auto.py` | ✅ | 1 | add_lua_docstrings_auto.py — Automatically inject /// docstrings above every |
| `tools/fix/add_test_markers.py` | ✅ | 1 | Add @covers / @stress / @golden / @security markers to Lurek2D Lua test files. |
| `tools/fix/docstring_fix.py` | ✅ | 1 | docstring_fix.py -- Auto-inject missing @param/@return tags into Lua API docstrings. |
| `tools/fix/expand_examples.py` | ✅ | 1 | tools/fix/expand_examples.py |
| `tools/fix/find_typed_params.py` | ✅ | 0 | find_typed_params.py — Find API parameters that already have explicit Lua types. |
| `tools/fix/fix_docstrings.py` | ✅ | 1 | fix_docstrings.py — Auto-fill missing # Parameters / # Returns / # Fields / |
| `tools/fix/fix_thread_api.py` | ✅ | 0 | One-shot fix for thread_api.rs docstrings. |
| `tools/fix/fix_type_stub_vars.py` | ✅ | 0 | tools/fix/fix_type_stub_vars.py |
| `tools/fix/fix_typeof_args.py` | ✅ | 0 | tools/fix/fix_typeof_args.py |
| `tools/fix/format_examples.py` | ✅ | 1 | tools/fix/format_examples.py |
| `tools/fix/improve_examples.py` | ✅ | 0 | tools/fix/improve_examples.py |
| `tools/fix/improve_lua_docstrings.py` | ✅ | 1 | improve_lua_docstrings.py — Rewrites existing thin/incorrect /// docstrings in |
| `tools/fix/strip_instance_method_comments.py` | ✅ | 0 | tools/fix/strip_instance_method_comments.py |
| `tools/fix/uncomment_examples.py` | ✅ | 0 | tools/fix/uncomment_examples.py |
| `tools/gen_all_docs.py` | ✅ | 4 | Convenience runner: regenerate the full Lurek2D documentation pipeline in one command. |
| `tools/github/ideas_to_github_issues.py` | ✅ | 0 | Create GitHub issues from each markdown file in docs/ideas/. |
| `tools/mods/mod_init.py` | ✅ | 1 | mod_init.py — Scaffold a minimal Lurek2D mod project. |
| `tools/screenshots/gen_demo_screenshots.py` | ✅ | 1 | gen_demo_screenshots.py — Capture a screen.png for every Lurek2D demo. |
| `tools/ui/fix_layouts.py` | ✅ | 2 | Fix Lurek2D TOML layout files. |
| `tools/ui/render_layout.py` | ✅ | 3 | Render Lurek2D TOML UI layout files to PNG wireframe previews. |
| `tools/ui/snap_to_grid.py` | ✅ | 2 | Snap every pixel-coordinate field in Lurek2D TOML layout files to a grid. |
| `tools/validate/_cag_common.py` | ✅ | 0 | Common helpers shared by CAG validator and audit tools. |
| `tools/validate/cag_validate.py` | ✅ | 28 | cag_validate.py — Lurek2D CAG layer validator. |
| `tools/validate/check_callbacks.py` | ✅ | 1 | check_callbacks.py — Verify that gen_docs_lua.py _callbacks() output has no embedded newlines. |
| `tools/validate/validate_game.py` | ✅ | 2 | validate_game.py — Validate Lua game scripts against the Lurek2D API surface. |
| `tools/validate/validate_lua_api.py` | ✅ | 7 | validate_lua_api.py -- Validates a Lurek2D lua_api file against the SKILL.md contract. |
| `tools/validate/validate_module_coverage.py` | ✅ | 2 | validate_module_coverage.py |

## Per-subfolder status

| Subdir | README | Scripts | Missing from README |
|---|:--:|---|---|
| `audit/` | ✅ | 24 | — |
| `demos/` | ✅ | 2 | — |
| `dev/` | ✅ | 1 | — |
| `dist/` | ✅ | 6 | — |
| `docs/` | ✅ | 16 | — |
| `fix/` | ✅ | 15 | — |
| `github/` | ✅ | 1 | — |
| `mods/` | ✅ | 1 | — |
| `screenshots/` | ✅ | 1 | — |
| `ui/` | ✅ | 3 | — |
| `validate/` | ✅ | 6 | — |

## Action list

- ✅ All scripts have docstrings/headers.


### Unreferenced by any agent/skill/prompt

- `tools/audit/gen_coverage_gaps.py` — gen_coverage_gaps.py — Generate an API gap report for Lurek2D.
- `tools/audit/module_audit.py` — module_audit.py — Lurek2D module restructuring audit.
- `tools/audit/test_analytics.py` — test_analytics.py — Lurek2D comprehensive test analytics.
- `tools/demos/organize_demos.py` — organize_demos.py — Three-in-one demos maintenance tool.
- `tools/dist/pack.ps1` — tools/pack.ps1
- `tools/dist/pack.py` — tools/pack.py — Pack a Lurek2D game directory into a .lurek archive.
- `tools/docs/gen_docs_rust.py` — gen_docs_rust.py — Generate compact inline Rust API reference from docs/logs/rust_api_data.json.
- `tools/docs/gen_lua_dev_docs.py` — gen_lua_dev_docs.py — Generate Lua developer documentation from lua_api *.rs files.
- `tools/docs/gen_lua_library_api.py` — gen_lua_library_api.py — Generate API reference docs from Lurek2D Lua library files.
- `tools/docs/gen_luadoc.py` — gen_luadoc.py — Generate LuaCATS type-annotation stubs for the Lurek2D VS Code extension.
- `tools/fix/find_typed_params.py` — find_typed_params.py — Find API parameters that already have explicit Lua types.
- `tools/fix/fix_thread_api.py` — One-shot fix for thread_api.rs docstrings.
- `tools/fix/fix_type_stub_vars.py` — tools/fix/fix_type_stub_vars.py
- `tools/fix/fix_typeof_args.py` — tools/fix/fix_typeof_args.py
- `tools/fix/improve_examples.py` — tools/fix/improve_examples.py
- `tools/fix/strip_instance_method_comments.py` — tools/fix/strip_instance_method_comments.py
- `tools/fix/uncomment_examples.py` — tools/fix/uncomment_examples.py
- `tools/github/ideas_to_github_issues.py` — Create GitHub issues from each markdown file in docs/ideas/.
- `tools/validate/_cag_common.py` — Common helpers shared by CAG validator and audit tools.
