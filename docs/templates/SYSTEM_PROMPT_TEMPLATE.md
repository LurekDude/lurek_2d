# System Prompt Template

> Use this template when updating or restructuring `.github/copilot-instructions.md`.
> The system prompt is the only CAG file always in context. Keep it lean — every line costs tokens on every interaction.

---

## Structure

```markdown
# <Engine Identity Title>

## Communication
<2–4 bullet rules for how the agent communicates>

## Engine Identity
<4–6 bullet facts: name, stack, license, target personas>

## Binding Constraints
<Grouped constraint bullets — each starts with a code (T-01, A-01, B-01, C-01, TST-01)>
- T-xx Architecture constraints
- A-xx Scope / feature constraints
- B-xx Tech-stack constraints
- C-xx API / naming constraints
- TST-xx Test placement constraints

## Cross-Artifact Sync
<Bullet rules for what must be updated together in the same commit>

## Discovery Directives
<Bullet pointers to source-of-truth files and docs>

## Work Session
<Standard layout for work/<session-name>/ and logging rules>

## Quality Gates
<Commands to run before every commit>

## Git Hygiene
<Branch, staging, commit-format, and changelog rules>

## Repository Layout
<One-line descriptions of top-level folders>
```

---

## Rules

- **Lean principle.** Every section must answer: "would an agent behave differently without this?" If no — cut it.
- **Binding constraints only.** Only add a constraint if violating it would break architecture coherence, CI, or shipping. No personal preferences.
- **Constraint codes.** Each constraint gets a stable code. Never renumber existing codes; add new codes at the end of the group.
- **No prose paragraphs.** Every rule is a bullet. No explanatory paragraphs in the system prompt — those belong in `docs/architecture/philosophy.md` or the relevant skill.
- **Keep total length under 300 lines.** Agent files and skills carry the HOW-TO detail. The system prompt carries only the invariants.
- **Update sync.** Any change to the system prompt that adds, removes, or renames a binding constraint, sync rule, or quality gate must also update `docs/architecture/cag-system.md` and `docs/CHANGELOG.md` in the same commit.

---

## Validation

After editing `.github/copilot-instructions.md`, run:

```pwsh
python tools/validate/cag_validate.py
python tools/audit/cag_link_check.py --strict
```

Both must exit 0.

---

## Example Binding Constraint Block

```markdown
## Binding Constraints
- T-01 Architecture: Five module groups (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration).
- T-02 No cycles, ever. The composition root is one-way.
- A-01 Runtime only. No embedded editor or IDE.
- B-01 LuaJIT is the main runtime. lua54 is a non-shipping fallback for CI.
- C-01 Use lurek.* only. No bare globals.
- TST-01 lurek.* behavior → tested in tests/lua/. Rust tests must not duplicate Lua-reachable coverage.
- TST-02 No #[cfg(test)] in src/. Rust unit tests → tests/rust/unit/<module>_tests.rs.
- TST-03 src/lua_api/<module>_api.rs: bindings only. Business logic stays in src/<module>/ as pure Rust.
- TST-04 Every mod.rs: only pub mod, pub use, attributes, and doc comments.
- TST-05 Demo tests → tests/lua/demos/test_<name>.lua. Screenshot demos → tests/demo_smoke_tests.rs with #[ignore].
- TST-06 One test file per module per layer: test_<module>_<layer>.lua.
```
