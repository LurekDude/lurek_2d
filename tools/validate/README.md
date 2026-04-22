# tools/validate — Schema & Structure Validators

Scripts that **check** files conform to required schemas, contracts, or
structural rules. Each script exits 1 on failure and prints a report.

## Scripts

| Script | Purpose | Key args |
|---|---|---|
| `cag_validate.py` | Validate all `.github/` CAG files (system prompt, agents, skills, prompts) against the templates in `work/cag-system-overhaul-20260418/reports/standards/`. Implements rules `E001-E004/W005`, `E101-E107/W108`, `E201-E205/W206`, `E301-E305/W306`. | `--type system_prompt\|agent\|skill\|prompt`, `--file <path>`, `--baseline`, `--write-baseline`, `--report <path>`, `--format text\|json` |
| `check_callbacks.py` | Verify `gen_docs_lua._callbacks()` output has no embedded newlines | — |
| `validate_game.py` | Validate a game/demo directory structure | `--all-examples`, `--all-demos` |
| `validate_lua_api.py` | Validate `src/lua_api/*_api.rs` against SKILL.md contract | file path or dir |
| `validate_module_coverage.py` | Verify every `src/` module has a matching `docs/specs/*.md` | — |
| `validate_changelog.py` | Validate `docs/CHANGELOG.md` structure: version ordering, duplicates, dates | `--strict`, `--format text\|json` |
| `validate_library.py` | Validate `content/library/` entries: required files, LDoc tags, return tables | `--library NAME`, `--strict`, `--format text\|json` |

The shared module `_cag_common.py` (frontmatter parser, link extractor, file
discovery) is re-used by the audit-side tools `tools/audit/cag_link_check.py`,
`tools/audit/cag_coverage.py`, and `tools/audit/cag_persona_matrix.py`.

### Baseline mode

Because the existing `.github/` files are mid-migration, the validator
supports a baseline workflow:

```powershell
# Capture the current violation set as the baseline (run once after major
# template changes):
python tools/validate/cag_validate.py --write-baseline

# Run in baseline mode — exits 0 unless new violations appear vs baseline:
python tools/validate/cag_validate.py --baseline
```

Strict mode (no `--baseline`) is used by P10 final validation and must
return zero errors and zero warnings.

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

# --- CHANGELOG validation ---
python tools/validate/validate_changelog.py
python tools/validate/validate_changelog.py --strict

# --- Library validation ---
python tools/validate/validate_library.py
python tools/validate/validate_library.py --library camera_utils --strict
```
