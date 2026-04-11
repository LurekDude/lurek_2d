# tools/validate — Schema & Structure Validators

Scripts that **check** files conform to required schemas, contracts, or
structural rules. Each script exits 1 on failure and prints a report.

## Scripts

| Script | Purpose | Key args |
|---|---|---|
| `cag_validate.py` | Validate all `.github/` CAG files (agents, skills, prompts) | `--type agent\|skill\|prompt`, `--file <path>` |
| `check_callbacks.py` | Verify `gen_docs_lua._callbacks()` output has no embedded newlines | — |
| `validate_game.py` | Validate a game/demo directory structure | `--all-examples`, `--all-demos` |
| `validate_lua_api.py` | Validate `src/lua_api/*_api.rs` against SKILL.md contract | file path or dir |
| `validate_module_coverage.py` | Verify every `src/` module has a matching `docs/specs/*.md` | — |

## Common usage

```powershell
# --- CAG validation ---
python tools/validate/cag_validate.py                        # all CAG files
python tools/validate/cag_validate.py --type agent            # agents only
python tools/validate/cag_validate.py --type skill            # skills only
python tools/validate/cag_validate.py --type prompt           # prompts only
python tools/validate/cag_validate.py --file .github/agents/developer.agent.md

# --- Game/Demo validation ---
python tools/validate/validate_game.py content/demos/hello_world/
python tools/validate/validate_game.py --all-examples
python tools/validate/validate_game.py --all-demos

# --- Lua API contract ---
python tools/validate/validate_lua_api.py src/lua_api/physics_api.rs
python tools/validate/validate_lua_api.py src/lua_api/

# --- Spec coverage ---
python tools/validate/validate_module_coverage.py
```
