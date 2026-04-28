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
- docs/specs/<module>.md is the canonical module reference.
- Keep the standard section order used by the repo.
- Update the matching spec section when source, bindings, or dependencies change.
- Do not reintroduce src/<module>/AGENT.md.
- Keep generated or source-derived facts correct to the current code.
- Validate the final shape with cag_validate.py when CAG rules apply.

## Companion File Index
- None.

## References
- docs/specs/
- tools/docs/gen_module_specs.py
- tools/validate/cag_validate.py