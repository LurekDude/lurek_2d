---
description: "Tune LuaJIT GC, FFI, or hot-path Lua patterns."
agent: Optimizer
tools: [tools/validate/cag_validate.py]
---
# Tune Lua Runtime

## Goal

Reduce Lua-side per-frame cost in a named hot path by tuning LuaJIT GC, FFI, or upvalue patterns and confirming the change with a measurement.

## Inputs

- `script_path` — value supplied by the user invocation.
- `objective` — value supplied by the user invocation.

## Steps

1. Load [skill: lua-runtime](.github/skills/lua-runtime/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Optimizer` agent, following the workflow in the loaded skill.
4. Run `python tools/validate/cag_validate.py` and the quality gates listed in [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring the prompt done.
5. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] All artifacts named in Goal exist on disk.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Skipping the skill-load step listed above.
- Running `git add .` instead of staging only files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/tune-lua-runtime <script_path> <objective>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-runtime
- **Inputs required**: script_path, objective
