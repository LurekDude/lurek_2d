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
- `docs/specs/<module>.md` describes exactly one module — one `src/<module>/` directory. It is not a narrative about a feature area or a design discussion. If the spec describes two modules, split it.
- Required sections (from `SPEC_TEMPLATE.md`): **Overview**, **Ownership**, **Public API**, **Invariants**, **Dependencies**, **Test Coverage**, **References**. The generator populates Public API from docstrings. All other sections are written manually and kept accurate.
- Auto-generated sections come from `python tools/docs/gen_module_specs.py`. When an auto-section is wrong, fix the Rust docstring or API annotation, then regenerate. Never hand-edit auto-sections.
- Version of truth: `docs/specs/<module>.md` is authoritative for what the module does, what it owns, and what it does not own. When a developer asks "should this go in module A or module B?", the spec Ownership section should answer. If it cannot, the spec is incomplete.
- After any structural src/ change (new module, renamed module, moved type), run `python tools/validate/validate_module_coverage.py`. It confirms the spec roster matches `src/` and that `docs/specs/README.md` has a row for each module.
- The Invariants section is the most underwritten section in practice. It must state: what preconditions must hold before any public function is called, what postconditions are guaranteed, and what the module refuses to do. An empty Invariants section is a coverage gap.
- Do not recreate `src/<module>/AGENT.md` patterns — they are retired. All module-scoped documentation belongs in `docs/specs/<module>.md`.
- Dependencies section must list tier relationships explicitly: which tier this module belongs to, which lower-tier modules it imports from, and which higher-tier modules must NOT import from it. This is the enforcement point for T-01/T-02.
- When a module is removed or merged, move the old spec to an archive folder if one exists, or add a `<!-- archived: merged into <module> -->` comment at the top and update `docs/specs/README.md`. Do not delete — historical specs are evidence for architecture decisions.
- spec prose should answer: "I own X. I do not own Y (that is module Z's job). Callers must guarantee A. I guarantee B. Never call me during state C."
## Companion File Index
- None.

## References
- docs/specs/
- docs/specs/SPEC_TEMPLATE.md
- tools/docs/gen_module_specs.py
- tools/validate/validate_module_coverage.py
