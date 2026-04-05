# Luna2D Tools Directory

This directory contains **permanent** CLI scripts for the Luna2D engine pipeline.

## Policy: Permanent vs Temporary Scripts

| Location | For |
|---|---|
| `tools/*.py / *.ps1 / *.sh / *.nsi` | Permanent CLI utilities — reusable by any agent, CI, or developer |
| `work/{session}/scripts/` | One-off or session-scoped scripts — archived at session end |

**Rule**: Do NOT create `_*.py` or any one-off helper scripts in `tools/`. If a script is temporary or session-specific, put it under `work/{session}/scripts/` instead. The `_` prefix is the signal that a file is a rogue/temp script and will be moved.

---

## Permanent Tools

### Documentation

| Script | Purpose | Output |
|---|---|---|
| `gen_all_docs.py` | Run the full doc pipeline in one command | `docs/` + `wiki/` |
| `gen_api_data.py` | Build master machine-readable API JSON | `docs/API/api_data.json` |
| `gen_docs_lua.py` | Compact Lua API reference | `docs/API/lua-api.md` |
| `gen_docs_rust.py` | Compact Rust API reference | `docs/API/rust-api.md` |
| `gen_docs_tests.py` | Test catalog from Rust test files | `docs/API/test-docs.md` |
| `gen_wiki_api.py` | Game-developer API cheatsheet | `wiki/API-Reference.md` |
| `gen_lua_api.py` | Legacy Lua reference (VS Code extension) | `docs/API/lua_api_reference_generated.md` |
| `collect_docs.py` | Rich Rust API collector with missing-doc report | `docs/API/api_generated.md` |
| `doc_coverage.py` | Rust + Lua docstring coverage analytics | `docs/API/doc_coverage.json` |
| `gen_test_docs.py` | Human-readable test documentation from metadata | `docs/API/test_docs.md` |

### Coverage & Analytics

| Script | Purpose | Output |
|---|---|---|
| `doc_coverage.py` | Count public items with/without `///` docs | `docs/API/doc_coverage.json` |
| `test_coverage.py` | Cross-reference API functions vs test files | stdout + `docs/API/test_coverage.json` |
| `integration_coverage.py` | Integration test coverage check | stdout |
| `module_audit.py` | Module structure and coverage audit | stdout |
| `quality_report.py` | Quality metrics report | stdout |

### Code Helpers

| Script | Purpose |
|---|---|
| `add_lua_docstrings.py` | Add missing `---` Lua docstrings interactively |
| `add_lua_docstrings_auto.py` | Auto-generate Lua docstrings |
| `improve_lua_docstrings.py` | Improve existing Lua docstrings |
| `doc_audit.py` | Audit Rust `///` doc comment quality |
| `golden_test.py` | Run and compare golden output tests |
| `validate_game.py` | Validate a game directory structure |
| `stress_report.py` | Parse and summarize stress test output |

### Lua API Doc Generation

| Script | Purpose |
|---|---|
| `gen_docs_lua.py` | Lua-facing API reference Markdown |
| `gen_lua_api.py` | Legacy Lua API reference (IDE extension) |

### Build & Distribution

| Script | Purpose |
|---|---|
| `dist.ps1` | Windows release build + zip archive |
| `dist.sh` | Linux/macOS release build + tarball |
| `install.ps1` | Install `luna.exe` locally (Windows) |
| `install.sh` | Install `luna2d` locally (Linux/macOS) |
| `installer.nsi` | NSIS Windows installer (installs engine + registers `.lunar` file association) |
| `pack.ps1` | Pack a game directory into a `.lunar` archive (PowerShell) |
| `pack.py` | Pack a game directory into a `.lunar` archive (Python, cross-platform) |

### Assets

| Script | Purpose |
|---|---|
| `gen_splash.py` | Regenerate `assets/splash.png` |
| `gen_icon.py` | Regenerate `assets/icon.ico` + `assets/icon.png` |

### CAG & Validation

| Script | Purpose |
|---|---|
| `cag_validate.py` | Validate all `.github/` CAG files |
| `ideas_to_github_issues.py` | Generate GitHub issues from `docs/ideas/*.md` |
| `print_issue_mapping.py` | Print idea → GitHub issue mapping |

---

## Usage Examples

```powershell
# Full doc pipeline
python tools/gen_all_docs.py

# Check what's missing docs (exits 1 if any)
python tools/collect_docs.py --report-missing

# Documentation coverage analytics
python tools/doc_coverage.py
python tools/doc_coverage.py --report-missing

# Test coverage analytics
python tools/test_coverage.py
python tools/test_coverage.py --json

# Generate human-readable test docs
python tools/gen_test_docs.py

# Validate CAG layer
python tools/cag_validate.py

# Build release binary and package
powershell tools/dist.ps1          # Windows
bash tools/dist.sh                 # Linux / macOS
```

---

## Adding a New Permanent Tool

1. Place the script in `tools/` (no leading `_`)
2. Add a `--help` argument (use `argparse`)
3. Add an entry to the table above in this README
4. Add an entry to the CLI Tools table in `.github/copilot-instructions.md`
5. Add a VS Code task in `.vscode/tasks.json` if it has interactive use
