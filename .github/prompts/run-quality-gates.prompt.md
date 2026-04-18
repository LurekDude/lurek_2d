---
description: "Run full quality gates: build, clippy, format check, and all tests."
mode: agent
loads_skills: []
loads_tools: []
expected_agent: Reviewer
inputs_required: []
---

# Run Quality Gates

## Goal

Execute all Lurek2D quality gates in sequence.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. `cargo fmt --check` — formatting compliance
2. `cargo clippy -- -D warnings` — lint with warnings as errors
3. `cargo build` — compilation check
4. `cargo test` — all tests pass
5. Report results for each gate

## Success Criteria

- [ ] Pass/fail for each gate
- [ ] Error details for any failures

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/run-quality-gates`
