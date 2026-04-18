---
description: "Full release readiness check for Lurek2D. Use before tagging a release or merging to main. Runs all quality gates and produces a go/no-go..."
mode: agent
loads_skills: [rust-coding, testing-rust, tools-cag-validation]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Manager
inputs_required: [VERSION]
---

# Workflow Release Check

## Goal

Full release readiness check for Lurek2D. Use before tagging a release or merging to main. Runs all quality gates and produces a go/no-go... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `VERSION` — intended release tag (e.g., `v0.2.0`)
- `PLATFORM` — target platform(s) for the release binary (e.g., `windows-x86_64`, `linux-x86_64`)

## Steps

1. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md), [skill: tools-cag-validation](.github/skills/tools-cag-validation/SKILL.md) before changing any files.
2. Must complete with 0 errors
3. Must complete with 0 warnings (treated as errors via `-D warnings`)
4. Must pass (no unformatted files)
5. All tests must pass; 0 failures, 0 panics
6. Must produce grade B or better on all file families
7. 0 CRITICAL issues, ≤ 3 HIGH issues
8. Window must open and display without panic
9. Close manually; verify no stderr errors
10. `docs/API/lua-api.md` — every `lurek.*` function in the code has an entry
11. `README.md` — version badge and feature list current
12. 0 known vulnerabilities in dependencies

## Success Criteria

- [ ] Console output from each gate
- [ ] Go/no-go verdict with specific blocking issues listed

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/workflow-release-check <VERSION>`
