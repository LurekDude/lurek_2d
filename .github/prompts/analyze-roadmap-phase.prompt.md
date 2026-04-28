---
description: "Audit a roadmap phase and report completion status."
---

# Analyze Roadmap Phase

## Goal
- The **Manager** owns this workflow from start to finish.
- It runs audit findings fix plan implementation tests documentation re-audit review phase closure.
- Nothing is skipped. Nothing is assumed done.

## Inputs
- DRY_RUN optional true to stop after producing the Gap Report without implementing anything (default: false)
- --

## Steps
- Load asset-pipeline, documentation, gpu-programming, lua-api-design, roadmap-planning, rust-coding, testing-rust before changing any files.
- Read this prompt's Inputs and confirm every required argument is present.
- Load any skill listed in loads_skills of this prompt's frontmatter.
- Execute the work as the Architect agent.
- Run the relevant quality gates from the quality-pipeline before declaring done.

## Success Criteria
- [ ] The Architect agent has produced the artifacts named in Goal.
- [ ] python tools/validate/cag_validate.py returns no new errors.

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /analyze-roadmap-phase <module>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: asset-pipeline, documentation, gpu-programming, lua-api-design, roadmap-planning, rust-coding, testing-rust
- **Inputs required**: module
