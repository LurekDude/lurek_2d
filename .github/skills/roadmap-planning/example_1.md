# Phase N — Title

> **Priority**: Critical | High | Medium | Low — one-line justification
> **Estimated Scope**: ~N files modified, ~N files added
> **Depends On**: Phase X (reason), Phase Y (reason)  or  Nothing
> **Blocks**: Phase X, Phase Y  or  Nothing

---

## Goal

One–three paragraphs. State WHAT changes, WHY it matters to game developers or the engine, and the single most important constraint or trade-off.

---

## Current State Analysis   (omit only for brand-new greenfield phases)

Describe what exists today that this phase changes or replaces. Tables or bullet lists. Reference actual file paths.

---

## Implementation Tasks

### N.1 Short Title

**File(s)**: list affected or created files

Description of the task. Code snippets (Rust or Lua) where the expected API or type is non-obvious.

**Agent**: Developer | Renderer | Physicist | Audio-Eng | Tester | Doc-Writer

### N.2 ...

(Continue numbered sub-tasks N.1, N.2, N.3 …)

---

## Acceptance Gates

Binary pass/fail checklist. Each item must be independently verifiable by running a command, reading a file, or observing a test result.

1. `cargo build` succeeds (or specific feature variant)
2. `cargo test` passes (or named test module)
3. Named Lua test or example runs end-to-end
4. Documentation file updated
5. Quality gates: `cargo clippy -- -D warnings` passes
