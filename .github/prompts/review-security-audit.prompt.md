---
description: "Security audit for Luna2D Lua sandboxing, filesystem access, and input validation. Use when adding filesystem features, untrusted script loading, or path APIs. Produces a threat model and finding list."
---

# Review: Security Audit

**Purpose**: Audit the Luna2D engine for security issues: Lua sandbox escapes, path traversal, untrusted script execution, and memory safety.
**Use When**: Adding filesystem access to Lua API, loading scripts from user-supplied paths, or modifying the `GameFS` sandbox.
**Do Not Use When**: Reviewing pure rendering or physics logic with no external inputs.
**Scope**: `src/filesystem/`, `src/lua_api/filesystem_api.rs`, `src/engine/app.rs`, and any newly added Lua API that accepts path or shell arguments.

## Inputs

- `CHANGED_FILES` — list of Rust files that changed or are new
- `THREAT_CONCERN` — specific concern to prioritize (e.g., "path traversal in `luna.fs.read`", "arbitrary Lua module loading")

## Steps

1. Load skill `dev-debugging/SKILL.md`
2. Check **Lua sandbox**:
   - `os`, `io`, `require`, `load`, `dofile`, `loadfile` must be nil'd or absent
   - `GameFS` must be the only I/O surface accessible to Lua
   - `luaL_openlibs` must NOT be called; confirm only allow-listed libraries are opened
3. Check **path validation** in `src/filesystem/vfs.rs`:
   - `canonicalize()` or equivalent path normalization applied before any file open
   - Paths must not resolve outside the game directory (no `../../../etc/passwd`)
   - Symlink traversal: resolved path must remain under `base_dir`
4. Check **argument validation** in `src/lua_api/filesystem_api.rs`:
   - Reject `null` bytes in path strings
   - Max path length enforced
5. Check **mlua `Lua::new()`** configuration:
   - Confirm `unsafe` Lua standard libs are not opened
   - Confirm `debug` library is not accessible
6. Review **error messages**: stack traces must not leak internal paths or Rust source locations to Lua scripts
7. Document each finding with: SEVERITY (CRITICAL/HIGH/MEDIUM/LOW), location, description, and recommended fix

## Outputs

- Threat model summary (attack surface, trust boundary diagram in prose)
- Numbered finding list with SEVERITY, location, description, fix recommendation
- PASS/FAIL verdict for the audit scope

## Acceptance

- [ ] No CRITICAL findings unaddressed
- [ ] Lua sandbox confirmed: `os`, `io`, `require`, `load`, `dofile` are nil
- [ ] Path traversal cannot escape game directory
- [ ] Null bytes in path strings rejected
- [ ] Review verdict documented

## References

**Required Skills**: `asset-pipeline`, `error-handling`
**Suggested Agents**: `Security`, `Developer`
**Related Prompts**: `review-unsafe-code.prompt.md`
**Docs**: `src/filesystem/vfs.rs`, `src/lua_api/filesystem_api.rs`
