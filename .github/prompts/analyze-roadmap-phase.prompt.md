---
description: "End-to-end roadmap phase completion: Manager-orchestrated workflow that audits a phase file, builds an evidence matrix of every deliverab..."
mode: agent
loads_skills: [asset-pipeline, documentation, gpu-programming, lua-api-design, roadmap-planning, rust-coding, testing-rust]
loads_tools: [tools/docs/collect_docs.py, tools/docs/gen_docs_lua.py]
expected_agent: Architect
inputs_required: [module]
---

# Analyze Roadmap Phase

## Goal

The **Manager** owns this workflow from start to finish.
It runs audit → findings → fix plan → implementation → tests → documentation → re-audit → review → phase closure.
Nothing is skipped. Nothing is assumed done.

## Inputs

- `DRY_RUN` — optional `true` to stop after producing the Gap Report without implementing anything (default: `false`)

---

## Steps

1. Load [skill: asset-pipeline](.github/skills/asset-pipeline/SKILL.md), [skill: documentation](.github/skills/documentation/SKILL.md), [skill: gpu-programming](.github/skills/gpu-programming/SKILL.md), [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), [skill: roadmap-planning](.github/skills/roadmap-planning/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. Read this prompt's Inputs and confirm every required argument is present.
3. Load any skill listed in `loads_skills` of this prompt's frontmatter.
4. Execute the work as the `Architect` agent.
5. Run the relevant quality gates from the [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring done.

## Success Criteria

- [ ] The `Architect` agent has produced the artifacts named in Goal.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-roadmap-phase <module>`
