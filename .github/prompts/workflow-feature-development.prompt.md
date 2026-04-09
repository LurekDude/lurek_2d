---
description: "Full feature development workflow from design to merged code. Use when starting a non-trivial feature that spans multiple modules. Orchestrates design, implementation, tests, and review."
---

# Workflow: Feature Development

**Purpose**: Orchestrate the full lifecycle of a non-trivial Lurek2D feature: API design → Rust implementation → tests → documentation → code review.
**Use When**: A feature requires changes in more than one module, needs API design decisions, or spans multiple specialist agent domains.
**Do Not Use When**: The change is a single-file bug fix or a small addition clearly owned by one specialist agent.
**Scope**: Full repository.

## Inputs

- `FEATURE_DESC` — one paragraph describing the feature and its game-developer-facing value
- `AFFECTED_MODULES` — list of `src/` modules that will change (e.g., `graphics/`, `lua_api/`)
- `PRIORITY` — `p1` (blocks other work), `p2` (normal), `p3` (nice-to-have)

## Steps

### Phase 1: Design (Lua-Designer + Architect)

1. Load skill `lua-api-design/SKILL.md`
2. Route to **Lua-Designer**: design the `lurek.*` API surface
   - Provide: feature description, affected namespace, reference engine equivalent if any
   - Get back: finalized function signatures, Lua usage example
3. Route to **Architect** if the feature needs a new module or changes module boundaries
   - Provide: current dependency graph, proposed new module
   - Get back: approved module structure and dependency direction

### Phase 2: Implementation (Renderer / Physicist / Audio-Eng / Developer)

4. Identify which specialist agent owns the implementation:
   - `src/graphics/` → **Renderer**
   - `src/physics/` → **Physicist**
   - `src/audio/` → **Audio-Eng**
   - Everything else → **Developer**
5. Route to the appropriate specialist with:
   - Finalized API spec from Phase 1
   - Affected file list
   - Acceptance criteria

### Phase 3: Testing (Tester)

6. Route to **Tester** with:
   - Implementation PR or changed files
   - Expected behaviour from API spec
   - Any edge cases identified during implementation
7. Gate: `cargo test --test <module>_tests` passes with new tests added

### Phase 4: Documentation (Doc-Writer)

8. Route to **Doc-Writer** with:
   - New `lurek.*` functions added
   - Any architecture changes
   - Updated module list

### Phase 5: Review (Reviewer)

9. Route to **Reviewer** with:
   - Full changed file list
   - Test results
   - Documentation updates
10. Gate: Reviewer signs off — no CRITICAL/HIGH issues

### Phase 6: DocString Audit (Doc-Writer)

11. For every `pub struct`, `pub enum`, `pub fn`, and module `//!` added or modified:
    - Expand description paragraphs to explain behaviour, design rationale, edge cases, and call sequence — not just the item name
    - Ensure `# Parameters`, `# Fields` / `# Variants`, and `# Returns` sections are present and accurate (these are machine-readable — never remove them)
    - Module-level `//!` must include a purpose statement, subsystem inventory, architecture note, and typical usage sequence
    - Lua API files (`src/lua_api/*.rs`) must document the `register()` function and every Lua-callable closure
12. Gate: `python tools/docs/collect_docs.py --report-missing` exits 0 — no public items lack a doc comment

### Phase 7: Spec File Cleanup

13. For each design / spec `.md` in `src/<module>/` that drove implementation:
    - Copy its content to `docs/API/<module>-design.md` (preserving tables, examples, and rationale)
    - Delete the original from `src/<module>/`
14. Gate: no spec-only `.md` files remain inside `src/`

### Phase 8: AGENT.md Update

15. Update (or create) `src/<module>/AGENT.md`:
    - **Tier** row must reflect the actual implemented tier (not "Design-stage / Stub")
    - **Status** row must say `Implemented — Full` (or `Implemented — Partial` with notes)
    - **Rust Tests** and **Lua Tests** rows must list correct file paths and test counts
    - Include a **Key Types** table and **Lua API Summary** section listing all exposed functions
    - Do NOT paste verbatim content from the deleted spec MDs — reference `docs/API/<module>-design.md` instead
16. Gate: AGENT.md accurately describes the implemented module

### Phase 9: AGENT.md Validation

17. Run `python tools/validate/cag_validate.py --file src/<module>/AGENT.md`
18. Gate: validator exits 0 or warns only about non-critical style issues (no ERROR-level findings)

## Outputs

- Working Rust implementation in `src/`
- Integration tests in `tests/`
- Updated `docs/API/lua_api_reference_generated.md`
- Updated `docs/architecture/engine-architecture.md` if modules changed
- Expanded docstrings on all new public items (full description + structured sections)
- Design doc at `docs/API/<module>-design.md`
- Accurate `src/<module>/AGENT.md`
- Clean `cargo check` (dev) → `cargo test && cargo clippy -- -D warnings` (final gate)

## Acceptance

- [ ] `cargo check` — 0 errors during development; `cargo test && cargo clippy -- -D warnings` at final gate
- [ ] `cargo test --test <module>_tests` — module tests pass during development
- [ ] New public API has at least one integration test
- [ ] `docs/API/lua_api_reference_generated.md` updated
- [ ] Reviewer signoff
- [ ] All public items have expanded docstrings (`# Parameters`, `# Fields`, `# Returns` present)
- [ ] `python tools/docs/collect_docs.py --report-missing` exits 0
- [ ] Spec MDs removed from `src/` — content in `docs/API/<module>-design.md`
- [ ] `src/<module>/AGENT.md` tier and test paths are accurate
- [ ] `python tools/validate/cag_validate.py --file src/<module>/AGENT.md` passes

## References

**Required Skills**: `lua-api-design`, `rust-coding`, `module-architecture`
**Suggested Agents**: `Manager`, `Lua-Designer`, `Developer`, `Tester`, `Reviewer`
**Related Prompts**: `design-api-surface.prompt.md`, `create-api-function.prompt.md`, `run-quality-gates.prompt.md`
