---
description: "Review module dependencies for correctness: no cross-domain imports, correct dependency direction."
agent: Architect
---
# Review Module Deps

## Goal

Audit module dependency graph for violations.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. Load [skill: module-architecture](.github/skills/module-architecture/SKILL.md) before changing any files.
2. For each domain module (`graphics`, `physics`, `audio`, `input`, `timer`, `filesystem`, `window`):
3. Check imports — should only use `crate::math::*` from other domain modules
4. No imports from other domain modules
5. Check `engine` — may import from all modules
6. Check `lua_api` — may import from `engine` + all domain modules
7. Report any violations with file path and import line

## Success Criteria

- [ ] No cross-domain module dependencies (except through `math`)
- [ ] `engine` dependency direction correct
- [ ] `lua_api` dependency direction correct

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-module-deps`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: module-architecture
