---
description: "Review module dependency rules."
---

# Review Module Deps

## Goal
- Audit module dependency graph for violations.

## Inputs
- None.

## Steps
- Load module-architecture before changing any files.
- For each domain module (graphics, physics, audio, input, timer, filesystem, window):
- Check imports should only use crate::math::* from other domain modules
- No imports from other domain modules
- Check engine may import from all modules
- Check lua_api may import from engine + all domain modules
- Report any violations with file path and import line

## Success Criteria
- [ ] No cross-domain module dependencies (except through math)
- [ ] engine dependency direction correct
- [ ] lua_api dependency direction correct

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-module-deps

## CAG Metadata
- **Mode**: agent
- **Loads skills**: module-architecture
