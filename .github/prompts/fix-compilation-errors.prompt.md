---
description: "Fix compilation errors, clippy warnings, or formatting issues in Rust source code."
mode: agent
loads_skills: [error-handling, rust-coding]
loads_tools: []
expected_agent: Developer
inputs_required: []
---

# Fix Compilation Errors

## Goal

Resolve Rust compilation errors, clippy warnings, or formatting failures.

## Inputs

- **Error output**: Compiler or clippy error messages
- **Affected files**: Which files have errors

## Steps

1. Load [skill: error-handling](.github/skills/error-handling/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Read the full error message (file, line, error code)
3. Read the affected code in context
4. Identify the fix (type mismatch, missing import, lifetime issue, etc.)
5. Apply the fix
6. Run `cargo build`, `cargo clippy`, `cargo fmt --check`
7. Run `cargo test` to verify no regressions

## Success Criteria

- [ ] `cargo build` succeeds
- [ ] `cargo clippy` — 0 warnings
- [ ] `cargo fmt --check` passes
- [ ] `cargo test` passes

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-compilation-errors`
