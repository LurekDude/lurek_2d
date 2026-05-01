---
description: "Load when creating or updating docs/specs/<module>.md merged module specs. Owns section layout, sync rules, and validate flow. Skip for Rust code, tests, or Lua scripts."
alwaysApply: false
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
- docs/specs/<module>.md is the canonical merged contract for one src module only; a spec should describe one ownership boundary.
- Keep section order aligned with docs/specs/SPEC_TEMPLATE.md and docs/specs/README.md.
- Manual and generated layers have different jobs: auto sections come from tools/docs/gen_module_specs.py, while Summary, General Info, Notes, and References explain behavior for humans.
- Do not hand-edit auto-generated sections; fix Rust docstrings, Lua API annotations, or source layout and regenerate instead.
- Sync prose to src/<module>/, src/lua_api/<module>_api.rs, tests, examples, and module-facing docs when public behavior or ownership moves.
- One module spec should describe the module as it exists in the current dependency model.
- References sections should point readers to the real source files, validators, or architecture docs.
- When a module is added, renamed, or structurally moved, update the spec index and run validate_module_coverage.py.

## References
- docs/specs/
- docs/specs/SPEC_TEMPLATE.md
- tools/docs/gen_module_specs.py
- tools/validate/validate_module_coverage.py
