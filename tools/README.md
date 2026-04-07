# Luna2D Tools Directory

Permanent CLI scripts for the Luna2D engine pipeline, organised by category.
Every subfolder has its own `README.md` with the full script list and usage examples.

## Policy: Permanent vs Temporary Scripts

| Location | For |
|---|---|
| `tools/<category>/` | Permanent CLI utilities — reusable by any agent, CI, or developer |
| `work/{session}/scripts/` | One-off or session-scoped scripts — archived at session end |

**Rule**: Do NOT create `_*.py` or one-off helper scripts in `tools/`. Temporary scripts
go under `work/{session}/scripts/` and are archived at session end.

---

## Subfolders

| Folder | Purpose |
|---|---|
| [`tools/docs/`](docs/README.md) | Documentation generators — produce `docs/API/`, `docs/logs/`, `wiki/` |
| [`tools/audit/`](audit/README.md) | Quality auditing, coverage analytics, gap reports |
| [`tools/fix/`](fix/README.md) | Code fixers and docstring improvers |
| [`tools/validate/`](validate/README.md) | Schema and structure validators (exit 1 on failure) |
| [`tools/assets/`](assets/README.md) | Branding and visual asset generators |
| [`tools/dist/`](dist/README.md) | Build, package, and install scripts |
| [`tools/github/`](github/README.md) | GitHub project management automation |

---

## Pipeline Orchestrator

```powershell
# Run the full documentation pipeline (all gen_* + coverage steps)
python tools/gen_all_docs.py
```

`gen_all_docs.py` lives at the tools root and calls scripts from `tools/docs/`
and `tools/audit/` in the correct dependency order.

---

## Key Scripts — Quick Reference

### Documentation

```powershell
python tools/docs/gen_lua_api.py                     # Lua API reference
python tools/docs/gen_lua_api.py --check             # coverage check (exit 1 if stale)
python tools/docs/gen_lua_api_skeleton.py --all      # generate lua_api stubs for all modules
python tools/docs/collect_docs.py --report-missing   # list items missing /// docs (exit 1 if any)
```

### Auditing & Coverage

```powershell
python tools/audit/doc_coverage.py                   # docstring coverage
python tools/audit/doc_coverage.py --report-missing  # missing items (exit 1 if any)
python tools/audit/test_coverage.py                  # test coverage summary
python tools/audit/audit_module.py physics           # end-to-end module audit
python tools/audit/validate_agent_md.py              # validate all AGENT.md files
```

### Validation

```powershell
python tools/validate/cag_validate.py                # validate entire .github/ CAG layer
python tools/validate/cag_validate.py --type agent   # agents only
python tools/validate/cag_validate.py --file PATH    # single file
python tools/validate/validate_lua_api.py src/lua_api/physics_api.rs
```

### Assets

```powershell
python tools/assets/gen_splash.py                    # regenerate assets/splash.png
python tools/assets/gen_icon.py                      # regenerate assets/icon.ico + icon.png
```

### Build & Distribution

```powershell
powershell -ExecutionPolicy Bypass -File tools/dist/dist.ps1        # Windows release package
bash tools/dist/dist.sh                                              # Linux/macOS release package
powershell -ExecutionPolicy Bypass -File tools/dist/install.ps1     # install locally (Windows)
bash tools/dist/install.sh                                           # install locally (Linux/macOS)
makensis tools/dist/installer.nsi                                    # NSIS installer
```

### GitHub

```powershell
python tools/github/ideas_to_github_issues.py       # create issues from docs/ideas/
```

---

## Adding a New Tool

1. Choose the right subfolder (`docs/`, `audit/`, `fix/`, `validate/`, `assets/`, `dist/`, or `github/`)
2. Add a module-level docstring with:
   - One-sentence purpose
   - Usage examples matching the new path
3. Update the subfolder's `README.md` table
4. If the tool is invoked from `gen_all_docs.py`, add it to the `SCRIPTS` list there
5. If it needs a VS Code task, add an entry in `.vscode/tasks.json`
