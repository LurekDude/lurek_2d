---
name: agent-md
description: "Load this skill when creating or maintaining merged module reference specs in docs/specs/<module>.md. It owns the required section structure, sync contract, and scaffold+validate workflow after the retirement of src/<module>/AGENT.md. Skip it for writing production Rust code, tests, or Lua scripts."
---
# agent-md

## Mission

# Module Reference Authoring and Maintenance Skill

## When To Load

- Creating a new `docs/specs/<module>.md` for a new engine module
- Updating a module reference after changing source files, public types, public functions, or Lua bindings
- Running `tools/audit/validate_agent_md.py` to validate the merged module reference format
- Running `tools/docs/gen_module_specs.py` to regenerate the collected sections from source
- Reviewing whether a module reference still matches its Rust source and Lua wrapper

## When To Skip

- Writing production Rust code → use `rust-coding` skill
- Writing or reviewing Lua API Rust bindings → use `lua-api-design` or `lua-rust-bridge`
- End-to-end module quality audits → use `module-audit` skill

## Domain Knowledge

### Single-Source System
Every engine module now uses one canonical documentation file:

| File | Purpose | Content |
|------|---------|---------|
| `docs/specs/<module>.md` | Merged module reference | General Info, Summary, Files, Types, Functions, Lua API Reference, References, Notes |

`src/<module>/AGENT.md` has been retired. Agents should load `docs/specs/<module>.md` directly when they need module context.

### Owns
- Required section structure for `docs/specs/<module>.md`
- `tools/docs/gen_module_specs.py` generation workflow
- `tools/audit/validate_agent_md.py` validation workflow
- Sync contract between module specs, Rust source, docstrings, and `src/lua_api/<module>_api.rs`

### Purpose
The merged spec is the canonical module reference an agent reads before working in a module. It combines the old overview content and the former deep spec content in one file so agents no longer need to chase two documentation layers.

Scripts may scaffold and refresh the source-derived sections, but the Summary and Notes remain manual prose. The goal is a reference that stays accurate enough for automated checks while still carrying module-specific design context that only a human or focused agent can write well.

Validate with: `python tools/audit/validate_agent_md.py --module <name>`
Regenerate with: `python tools/docs/gen_module_specs.py --module <name>`

### Required Format (`docs/specs/<module>.md`)
The merged module reference must contain these sections in order:

1. `# <module>`
2. `## General Info`
3. `## Summary`
4. `## Files`
5. `## Types`
6. `## Functions`
7. `## Lua API Reference`
8. `## References`
9. `## Notes`

### `## General Info`

Keep this short and factual. Minimum fields:
- Module group
- Source path
- Lua API path(s)
- Primary Lua namespace
- Rust test path(s)
- Lua test path(s)

### `## Summary`

- Several paragraphs of plain text
- Explain the module's purpose, scope boundary, and why its responsibilities live here
- Start from the prior AGENT.md purpose text when migrating, then expand it manually from the actual source code
- Write module by module; do not mass-generate vague summaries

### `## Files`

- One bullet per `.rs` file under `src/<module>/`
- Format: `- \`file.rs\`: purpose`
- Source-derived and safe to regenerate

### `## Types`

- One bullet per public Rust type (`struct`, `enum`, `trait`, `type`)
- Format: `- \`TypeName\` (\`kind\`, \`file.rs\`): purpose`
- Source-derived and safe to regenerate

### `## Functions`

- One bullet per public Rust function or method that the source scanner finds
- Format: `- \`Type::method\` (\`file.rs\`): purpose`
- Source-derived and safe to regenerate

### `## Lua API Reference`

- Include binding path(s) and namespace when present

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
