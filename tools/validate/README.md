# tools/validate — Schema & Structure Validators

Scripts that **check** files conform to required schemas, contracts, or
structural rules. Each script exits 1 on failure and prints a report.

## Scripts

| Script | Purpose |
|---|---|
| `cag_validate.py` | Validate all `.github/` CAG files (agents, skills, prompts) |
| `check_callbacks.py` | Verify `gen_docs_lua._callbacks()` output has no embedded newlines |
| `validate_game.py` | Validate a game/demo directory structure |
| `validate_lua_api.py` | Validate a `src/lua_api/*_api.rs` file against the SKILL.md contract |

## Common usage

```powershell
# Validate entire CAG layer
python tools/validate/cag_validate.py

# Validate specific CAG artifact type
python tools/validate/cag_validate.py --type agent
python tools/validate/cag_validate.py --type skill
python tools/validate/cag_validate.py --type prompt

# Validate a single CAG file
python tools/validate/cag_validate.py --file .github/agents/developer.agent.md

# Validate a game directory
python tools/validate/validate_game.py content/demos/hello_world/
python tools/validate/validate_game.py --all-examples

# Validate a lua_api file
python tools/validate/validate_lua_api.py src/lua_api/physics_api.rs
```
