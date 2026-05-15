# tools/validate â€” Schema & Structure Validators

Scripts that **check** files conform to required schemas, contracts, or
structural rules. Each script exits 1 on failure and prints a report.

## Scripts

| Script | Purpose | Key args |
|---|---|---|
| `cag_validate.py` | Validate all `.github/` CAG files (system prompt, agents, skills, prompts) against the live schema in `docs/architecture/cag-system.md`. Implements rules `E001-E004/W005`, `E101-E113/W108`, `E201-E205/W206`, `E301-E305/W306`. Agent files must not define `Autonomy`; that rule lives in the system prompt. | `--type system_prompt\|agent\|skill\|prompt`, `--file <path>`, `--baseline`, `--write-baseline`, `--report <path>`, `--format text\|json` |
| `check_callbacks.py` | Verify `gen_docs_lua._callbacks()` output has no embedded newlines | â€” |
| `validate_game.py` | Validate a game/demo directory structure | `--all-examples`, `--all-demos` |
| `validate_generated_lua_stubs.py` | Validate committed Lua API generated artifacts against fresh generator output and fail when the generated Lua API data is incomplete (missing summaries, param docs, return docs, or class docs) | `--format text\|json` |
| `validate_lua_api.py` | Validate `src/lua_api/*_api.rs` against the Lua API doc contract: summary length, `@param` coverage, `@return` coverage, and Lua-visible object/class descriptions | file path or dir |
| `validate_rust_source_docs.py` | Validate file-level `//!` headers plus phase-1 `///` summaries for public Rust items under `src/**/*.rs` | optional file/dir targets, `--format text\|json` |
| `validate_module_coverage.py` | Verify every `src/` module has a matching `docs/specs/*.md` | â€” |
| `validate_changelog.py` | Validate `docs/CHANGELOG.md` structure: version ordering, duplicates, dates | `--strict`, `--format text\|json` |
| `validate_library.py` | Validate `library/` entries: required files, LDoc tags, return tables | `--library NAME`, `--strict`, `--format text\|json` |

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

# Run in baseline mode â€” exits 0 unless new violations appear vs baseline:
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

# --- Rust source doc contract ---
python tools/validate/validate_rust_source_docs.py
python tools/validate/validate_rust_source_docs.py src/lib.rs
python tools/validate/validate_rust_source_docs.py src/globe/ --format json

# --- Generated Lua stub parity ---
python tools/validate/validate_generated_lua_stubs.py
python tools/validate/validate_generated_lua_stubs.py --format json

# --- Spec coverage ---
python tools/validate/validate_module_coverage.py

# --- Combined source docs gate ---
python tools/validate/validate_rust_source_docs.py
python tools/validate/validate_lua_api.py src/lua_api
python tools/validate/validate_generated_lua_stubs.py
python tools/validate/validate_module_coverage.py

# --- CHANGELOG validation ---
python tools/validate/validate_changelog.py
python tools/validate/validate_changelog.py --strict

# --- Library validation ---
python tools/validate/validate_library.py
python tools/validate/validate_library.py --library camera_utils --strict
```

