---
description: "Run the full feature-development workflow."
---
# Workflow Feature Development

## Goal
- Run a full feature workflow from design to verified code.

## Inputs
- FEATURE_DESC: one short feature summary and user value.
- AFFECTED_MODULES: src/ modules that will change.
- PRIORITY: p1, p2, or p3.

## Steps
- Load documentation, lua-api-design, lua-rust-bridge, module-architecture, rust-coding, and testing-rust.
- Read docs/architecture/philosophy.md, docs/architecture/engine-architecture.md, and docs/architecture/test-framework.md.
- Read docs/specs/<module>.md for each affected module.
- Stop if the feature breaks binding constraints.
- Route Lua API design to Lua-Designer when lurek.* changes.
- Route structure changes to Architect when modules or boundaries change.
- Keep domain logic in src/<module>/.
- Keep src/lua_api/<module>_api.rs thin. Only validate, convert, and delegate there.
- Keep tests out of src/.
- Keep mod.rs files as declarations only.
- Write Lua tests for lurek.* behavior and Rust unit tests only for Rust-only internals.
- Update docs/specs/<module>.md, content/examples/<module>.lua, and docs/CHANGELOG.md.
- Run python tools/gen_all_docs.py after API changes.
- Finish with cargo check --tests.

## Success Criteria
- [ ] Domain logic is in src/<module>/ only.
- [ ] Lua wrapper files stay thin.
- [ ] No tests were added under src/.
- [ ] mod.rs stays declarations-only.
- [ ] Needed Lua tests and Rust unit tests exist in the right place.
- [ ] Public item docstrings are updated.
- [ ] docs/specs/<module>.md is updated.
- [ ] Generated API docs are refreshed after API changes.
- [ ] content/examples/<module>.lua shows the new API.
- [ ] docs/CHANGELOG.md is updated.
- [ ] cargo check --tests passes.

## Anti-patterns
- Skip the success check.
- Use git add .
- Add tests under src/.
- Add structs, enums, impls, or functions to mod.rs.
- Put business logic in lua_api closures.
- Skip gen_all_docs.py after API changes.
- Add a Lua test and forget harness registration.

## Example Invocation
- /workflow-feature-development FEATURE_DESC AFFECTED_MODULES PRIORITY

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation, lua-api-design, lua-rust-bridge, module-architecture, rust-coding, testing-rust
- **Inputs required**: FEATURE_DESC, AFFECTED_MODULES, PRIORITY
