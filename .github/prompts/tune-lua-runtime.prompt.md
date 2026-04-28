---
description: "Tune Lua runtime behavior and hot paths."
---

# Tune Lua Runtime

## Goal
- Reduce Lua-side per-frame cost in a named hot path by tuning LuaJIT GC, FFI, or upvalue patterns and confirming the change with a measurement.

## Inputs
- script_path
- objective

## Steps
- Load lua-runtime before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Optimizer agent, following the workflow in the loaded skill.
- Run python tools/validate/cag_validate.py and the quality gates listed in quality-pipeline before declaring the prompt done.
- Add a docs/CHANGELOG.md entry under the current version.

## Success Criteria
- [ ] All artifacts named in Goal exist on disk.
- [ ] python tools/validate/cag_validate.py returns no new errors.
- [ ] docs/CHANGELOG.md has a new entry under the current version.

## Anti-patterns
- Skipping the skill-load step listed above.
- Running git add . instead of staging only files this prompt produced.

## Example Invocation
- /tune-lua-runtime <script_path> <objective>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-runtime
- **Inputs required**: script_path, objective
