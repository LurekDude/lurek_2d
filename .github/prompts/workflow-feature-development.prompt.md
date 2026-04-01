---
description: "Full feature development workflow from design to merged code. Use when starting a non-trivial feature that spans multiple modules. Orchestrates design, implementation, tests, and review."
---

# Workflow: Feature Development

**Purpose**: Orchestrate the full lifecycle of a non-trivial Luna2D feature: API design → Rust implementation → tests → documentation → code review.
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
2. Route to **Lua-Designer**: design the `luna.*` API surface
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
7. Gate: `cargo test` passes with new tests added

### Phase 4: Documentation (Doc-Writer)

8. Route to **Doc-Writer** with:
   - New `luna.*` functions added
   - Any architecture changes
   - Updated module list

### Phase 5: Review (Reviewer)

9. Route to **Reviewer** with:
   - Full changed file list
   - Test results
   - Documentation updates
10. Gate: Reviewer signs off — no CRITICAL/HIGH issues

## Outputs

- Working Rust implementation in `src/`
- Integration tests in `tests/`
- Updated `docs/lua_api_reference.md`
- Updated `docs/architecture.md` if modules changed
- Clean `cargo build`, `cargo clippy`, `cargo test`

## Acceptance

- [ ] `cargo build` — 0 errors, 0 warnings
- [ ] `cargo clippy` — 0 warnings
- [ ] `cargo test` — all tests pass
- [ ] New public API has at least one integration test
- [ ] `docs/lua_api_reference.md` updated
- [ ] Reviewer signoff

## References

**Required Skills**: `lua-api-design`, `rust-coding`, `module-architecture`
**Suggested Agents**: `Manager`, `Lua-Designer`, `Developer`, `Tester`, `Reviewer`
**Related Prompts**: `design-api-surface.prompt.md`, `create-api-function.prompt.md`, `run-quality-gates.prompt.md`
