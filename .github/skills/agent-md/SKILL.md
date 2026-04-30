---
name: agent-md
description: "Load this skill when creating or updating docs/specs/<module>.md merged module specs. It owns section layout, sync rules, and validate flow. Skip it for Rust code, tests, or Lua scripts."
---
# agent-md

## Mission
- Own docs/specs/<module>.md structure, sync rules, and validation flow.

## When To Load
- Create a new merged module spec.
- Update docs/specs/<module>.md after source changes.
- Check section order or spec sync rules.

## When To Skip
- Rust implementation.
- Test writing.
- Lua script work.

## Domain Knowledge
- docs/specs/<module>.md is the canonical merged contract for one src module only; a spec should describe one ownership boundary, not blend multiple modules into a convenience narrative.
- Keep section order aligned with docs/specs/SPEC_TEMPLATE.md and docs/specs/README.md because the generator and audit tooling assume the merged spec format stays stable.
- Manual and generated layers have different jobs: auto sections come from tools/docs/gen_module_specs.py, while Summary, General Info, Notes, and References explain behavior, ownership, and caveats for humans.
- Do not hand-edit auto-generated sections when the source is wrong; fix Rust docstrings, Lua API annotations, or source layout and regenerate instead of fighting the toolchain.
- Sync prose to src/<module>/, src/lua_api/<module>_api.rs, tests, examples, and any module-facing docs when public behavior or ownership moves.
- One module spec should describe the module as it exists in the current dependency model, including the correct tier and neighboring responsibilities from docs/specs/README.md.
- Do not recreate retired src/<module>/AGENT.md patterns or split module truth across wiki, README, and spec files; the spec is the contract anchor for that module.
- References sections should point readers to the real source files, validators, or architecture docs that matter for the module, not generic repo links.
- When a module is added, renamed, or structurally moved, update the spec index and run validate_module_coverage.py so coverage tooling sees the same module roster.
- Good spec prose here explains what the module owns, what it depends on, and which adjacent module should be changed instead when a boundary question appears.
## Companion File Index
- None.

## References
- docs/specs/
- docs/specs/SPEC_TEMPLATE.md
- tools/docs/gen_module_specs.py
- tools/validate/validate_module_coverage.py
