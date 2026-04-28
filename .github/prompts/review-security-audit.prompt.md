---
description: "Run a security audit."
---

# Review Security Audit

## Goal
- Security audit for Lurek2D Lua sandboxing, filesystem access, and input validation. Use when adding filesystem features, untrusted script...

## Inputs
- CHANGED_FILES list of Rust files that changed or are new
- THREAT_CONCERN specific concern to prioritize (e.g., "path traversal in lurek.filesystem.read", "arbitrary Lua module loading")

## Steps
- Load asset-pipeline, dev-debugging, error-handling before changing any files.
- Load skill dev-debugging/SKILL.md
- Check **Lua sandbox**:
- os, io, require, load, dofile, loadfile must be nil'd or absent
- GameFS must be the only I/O surface accessible to Lua
- luaL_openlibs must NOT be called; confirm only allow-listed libraries are opened
- Check **path validation** in src/filesystem/vfs.rs:
- canonicalize() or equivalent path normalization applied before any file open
- Paths must not resolve outside the game directory (no ../../../etc/passwd)
- Symlink traversal: resolved path must remain under base_dir
- Check **argument validation** in src/lua_api/filesystem_api.rs:
- Reject null bytes in path strings

## Success Criteria
- [ ] Threat model summary (attack surface, trust boundary diagram in prose)
- [ ] Numbered finding list with SEVERITY, location, description, fix recommendation
- [ ] PASS/FAIL verdict for the audit scope

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-security-audit

## CAG Metadata
- **Mode**: agent
- **Loads skills**: asset-pipeline, dev-debugging, error-handling
