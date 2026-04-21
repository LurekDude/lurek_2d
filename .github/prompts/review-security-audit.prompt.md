---
description: "Security audit for Lurek2D Lua sandboxing, filesystem access, and input validation. Use when adding filesystem features, untrusted script..."
---
# Review Security Audit

## Goal

Security audit for Lurek2D Lua sandboxing, filesystem access, and input validation. Use when adding filesystem features, untrusted script... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `CHANGED_FILES` — list of Rust files that changed or are new
- `THREAT_CONCERN` — specific concern to prioritize (e.g., "path traversal in `lurek.filesystem.read`", "arbitrary Lua module loading")

## Steps

1. Load [skill: asset-pipeline](.github/skills/asset-pipeline/SKILL.md), [skill: dev-debugging](.github/skills/dev-debugging/SKILL.md), [skill: error-handling](.github/skills/error-handling/SKILL.md) before changing any files.
2. Load skill `dev-debugging/SKILL.md`
3. Check **Lua sandbox**:
4. `os`, `io`, `require`, `load`, `dofile`, `loadfile` must be nil'd or absent
5. `GameFS` must be the only I/O surface accessible to Lua
6. `luaL_openlibs` must NOT be called; confirm only allow-listed libraries are opened
7. Check **path validation** in `src/filesystem/vfs.rs`:
8. `canonicalize()` or equivalent path normalization applied before any file open
9. Paths must not resolve outside the game directory (no `../../../etc/passwd`)
10. Symlink traversal: resolved path must remain under `base_dir`
11. Check **argument validation** in `src/lua_api/filesystem_api.rs`:
12. Reject `null` bytes in path strings

## Success Criteria

- [ ] Threat model summary (attack surface, trust boundary diagram in prose)
- [ ] Numbered finding list with SEVERITY, location, description, fix recommendation
- [ ] PASS/FAIL verdict for the audit scope

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-security-audit`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: asset-pipeline, dev-debugging, error-handling
