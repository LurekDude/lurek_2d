---
description: "Complete phase implementation from a roadmap file. Runs pre-flight analysis of what already exists, audits external libraries so nothing..."
---
# Implement Roadmap Phase

## Goal

End-to-end delivery of a single roadmap phase: read the phase file, understand what already exists, build a concrete implementation plan, write the code, document every public item, test everything, run quality gates, generate updated API docs, and mark the phase complete.

## Inputs

- `SCOPE` — optional: `full` (all tasks in the phase) or a comma-separated list of task IDs to implement, e.g., `2.1, 2.3` (default: `full`)
- `DRY_RUN` — optional `true` to only produce the plan without writing any code (default: `false`)

---

## Steps

1. Load [skill: asset-pipeline](.github/skills/asset-pipeline/SKILL.md), [skill: gpu-programming](.github/skills/gpu-programming/SKILL.md), [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), [skill: roadmap-planning](.github/skills/roadmap-planning/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md), [skill: testing-rust](.github/skills/testing-rust/SKILL.md) before changing any files.
2. `.github/skills/roadmap-planning/SKILL.md` — phase format, acceptance gates, status symbols
3. `.github/skills/lua-api-design/SKILL.md` — `lurek.*` naming, parameter conventions, API alignment
4. `.github/skills/rust-coding/SKILL.md` — Rust conventions, error handling, visibility
5. `.github/skills/testing-rust/SKILL.md` — test patterns, float comparisons, headless safety
6. Load domain skill matching the phase: `gpu-programming`, `physics-engine`, `audio-integration`, `input-handling`, `asset-pipeline` — whichever applies; for font/text consult `docs/specs/render.md`
7. Picking up a phase that is `⬜ Not Started` or `🔄 In Progress`
8. Producing a commit-ready implementation with tests, docs, and a phase status update
9. You only need to update the status of an already-completed phase → use `workflow-update-roadmap-phase`
10. You are designing a brand-new phase that doesn't exist yet → use `create-roadmap-phase`
11. You only need to add a single function → use `create-api-function`
12. Phase number and title

## Success Criteria

- [ ] `cargo build` succeeds with zero errors
- [ ] `cargo test` passes — all existing tests still pass; new tests for all new functions present
- [ ] `cargo clippy -- -D warnings` produces zero warnings
- [ ] `cargo fmt --check` produces zero diffs
- [ ] `python tools/docs/collect_docs.py --report-missing` exits 0 (zero missing public docs)
- [ ] `python tools/docs/collect_docs.py` completes and `docs/lua-api.md` is updated
- [ ] Every new `lurek.*` function appears in `docs/lua-api.md`
- [ ] Every new `lurek.*` function has a corresponding Lua test in `tests/lua/`
- [ ] Every new Rust public function has a corresponding Rust test in `tests/<module>_tests.rs`
- [ ] API parity check passed: new functions use same parameter order and semantics as a similar game engine equivalents
- [ ] No external library capability is hand-rolled (the crate audit table from Step 3d is satisfied)
- [ ] `docs/architecture/engine-architecture.md` reflects any structural changes

## Anti-patterns

- You only need to update the status of an already-completed phase → use `workflow-update-roadmap-phase`
- You are designing a brand-new phase that doesn't exist yet → use `create-roadmap-phase`
- You only need to add a single function → use `create-api-function`

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/implement-roadmap-phase <function> <module> <reason> <scenario>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: asset-pipeline, gpu-programming, lua-api-design, roadmap-planning, rust-coding, testing-rust
- **Inputs required**: function, module, reason, scenario
