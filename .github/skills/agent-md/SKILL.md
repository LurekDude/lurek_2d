---
name: agent-md
description: "Load this skill when creating or maintaining AGENT.md files inside Luna2D src/ module directories. Owns required section structure (short overview in src/, full spec in specs/), sync contracts, and the scaffold+validate workflow. Skip it for writing production Rust code, tests, or Lua scripts."
---

# AGENT.md Authoring and Maintenance Skill

## The Two-Layer System

Every module uses a two-file documentation structure:

| File | Purpose | Content |
|------|---------|--------|
| `src/<module>/AGENT.md` | **Short overview** — loaded by every agent entering the module | Metadata table, one-paragraph Purpose, Source Files list, pointer to spec |
| `specs/<module>.md` | **Full technical spec** — loaded when deep detail is needed | Architecture diagram, all types, full Lua API, examples, references, notes |

**Read order**: Load `src/<module>/AGENT.md` first. Only load `specs/<module>.md` when you need architecture diagrams, full type details, Lua API docs, or cross-module references.

**Write rule**: When anything changes in a module, **both** files must be updated in the same commit — the short AGENT.md for the surface summary, and the full spec for deep detail.

## Load When

- Creating a new `src/<module>/AGENT.md` (short) and `specs/<module>.md` (full) from scratch
- Updating an existing AGENT.md or spec after changing source files, types, or Lua API bindings
- Running `tools/audit/validate_agent_md.py` to check compliance
- Reviewing whether AGENT.md / spec are in sync with the Lua wrapper

## Owns

- Required section structure for `src/<module>/AGENT.md` (short overview format)
- Required section structure for `specs/<module>.md` (full spec format)
- `tools/audit/validate_agent_md.py` — validation and scaffold tool
- Sync contract between AGENT.md, specs/, source `.rs` files, `///` docstrings, and `src/lua_api/<module>_api.rs`

## Does Not Cover

- Writing production Rust code → use `rust-coding` skill
- Writing or reviewing Lua API Rust bindings → use `lua-api-design` skill
- End-to-end module quality audits → use `module-audit` skill

## Purpose

Every `src/<module>/` directory MUST contain a hand-maintained `AGENT.md` file.
This file is the canonical domain reference an AI agent reads before working
in that module. It is **not auto-generated** — it is written and updated
by the agent that last touched the module. Scripts can scaffold repetitive
sections and validate completeness, but the prose and accuracy are manual.

Validate with: `python tools/audit/validate_agent_md.py --module <name>`
Scaffold missing sections: `python tools/audit/validate_agent_md.py --scaffold <name>`

---

## Short AGENT.md Format (`src/<module>/AGENT.md`)

The short AGENT.md must contain exactly these sections in order:

1. **H1 heading** — `# \`<module>\` — Agent Reference`
2. **Metadata table** — Tier, Status, Lua API, Source, Rust Tests, Lua Tests, Architecture link
3. **`## Purpose`** — One paragraph: what the module does and its scope boundary. Target 2–5 sentences. Must let an agent decide whether to open this module or a different one.
4. **`## Source Files`** — Table mapping every `.rs` file in `src/<module>/` to its one-line purpose. Keep in sync when files are added or removed.
5. **`## Full Specification`** — Standard footer paragraph pointing to `specs/<module>.md`.

**Do NOT copy full architecture diagrams, type docs, Lua API tables, or examples into the short AGENT.md.** Those live in `specs/<module>.md`.

---

## Full Spec Format (`specs/<module>.md`)

The full spec is the old AGENT.md with complete technical detail. Required sections (ERROR if missing) are listed below. The spec is the canonical reference an agent loads when it needs deep module knowledge.

---

## Required Sections (ERROR if missing)

### 1. Header Metadata Table

Must be the first content after the `# \`<module>\` — Agent Reference` heading.

```markdown
| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full / Partial / Stub                  |
| **Lua API**    | `luna.<module>` (or `—` if none)                     |
| **Source**     | `src/<module>/`                                      |
| **Rust Tests** | `tests/unit/<module>_tests.rs`                       |
| **Lua Tests**  | `tests/lua/unit/test_<module>.lua` (or `—` if none)  |
| **Architecture** | `docs/API/<module>-design.md` (if exists, else `—`) |
```

### 2. `## Summary`

- **Minimum 500 characters, target 1000**
- Must cover: what the module does, how it works, key design decisions, what is
  intentionally NOT included (scope boundary)
- Agents must be able to determine from this alone whether to load this module
  or a different one

### 3. `## Architecture`

ASCII block diagram of the module's internal structure. Show: types, data flow,
subsystems, and relationships between components.

### 4. `## Source Files`

Table mapping every `.rs` file in `src/<module>/` (except `mod.rs`) to its
one-line purpose. Must stay in sync — run `validate_agent_md.py` to detect
unlisted files.

### 5. `## Submodules`

One subsection per Rust submodule. Each entry names the submodule path and
lists every public `struct` and `enum` with a one-line description.

### 6. `## Key Types`

Two H3 subsections: `### Structs` and `### Enums`. Every `pub struct` and
`pub enum` gets an H4 entry with its full path (`<module>::<file>::Name`) and a
description taken from its `///` doc comment. Every public function that is a
constructor or primary operation should be mentioned here too.

### 7. `## Lua API`

Paragraph describing the full Lua-facing surface. Must reference the file
`src/lua_api/<module>_api.rs` (or `src/lua_api/<module>_api/` for module dirs).
Enumerate all exposed function names in `luna.<module>.*`. If there is no Lua API,
write `No Lua API — internal Rust module only.`

### 8. `## Lua Examples`

At least one `\`\`\`lua` block showing real usage of `luna.<module>.*`. Must be
correct against the actual API. Cover the most common use case in `luna.load` /
`luna.update` / `luna.draw` pattern.

### 9. `## Item Summary`

Markdown table:

```markdown
| Kind       | Count |
|------------|-------|
| `struct`   | N     |
| `enum`     | N     |
| `fn`       | N     |
| **Total**  | **N** |
```

### 10. `## References`

List every other module this module relates to, the direction of the
relationship, and the separation of duties. Format:

```markdown
| Module          | Relationship | Notes                           |
|-----------------|--------------|---------------------------------|
| `engine`        | Imports from | Uses SharedState and SlotMap    |
| `math`          | Imports from | Vec2, Color, Rect               |
| `lua_api`       | Imported by  | Binds public API to Lua         |
```

Also include: which modules are **similar** and what differentiates them
(e.g., `sound` vs `audio`, `image` vs `graphics`).

### 11. `## Notes`

Unique facts an agent must know before editing this module:
- Hardware or OS-specific behaviour (e.g., "audio falls back to headless on CI")
- External crate constraints (e.g., "rapier2d 0.32 — do not call from multiple threads")
- Known limitations or intentional omissions
- Best practices for this module (what patterns are safe, which are fragile)
- Breaking change surface (what Lua scripts will break if this API changes)

---

## Sync Contract

`AGENT.md` (short) and `specs/<module>.md` (full) are both manual truth sources. Keep both in sync with:

| What changes               | What to update                                      |
|----------------------------|----------------------------------------------------- |
| New `.rs` file added       | `AGENT.md` Source Files table + `specs/` Source Files table + Submodules |
| New `pub struct` / `enum`  | `specs/` Submodules, Key Types, Item Summary count  |
| New Lua binding added      | `specs/` Lua API section + Lua Examples             |
| Lua binding renamed        | `specs/` Lua API section + Lua Examples             |
| Dependency added / removed | `specs/` References table + Notes if behaviour changes |
| Scope boundary change      | `AGENT.md` Purpose + `specs/` Summary + Notes       |
| `demos/` or `examples/` changed | Re-verify `specs/` Lua Examples are still correct |
| `library/` module changed  | Re-verify any `specs/` that document that API are still correct |

**Rule**: If you touched a `.rs` file in `src/<module>/` or its Lua API wrapper,
you MUST update both `AGENT.md` **and** `specs/<module>.md` before the commit.

---

## Scaffolding vs Manual Prose

The scaffold tool (`validate_agent_md.py --scaffold`) auto-fills:
- Source Files table (from `src/<module>/*.rs`)
- Submodules skeleton (from `//!` doc comments)
- Key Types skeleton (from `pub struct` / `pub enum` names)
- Item Summary counts (from a source scan)

**All prose descriptions inside those sections are manual.** The scaffold
produces `TODO:` placeholders that must be replaced with accurate descriptions.
Do not leave `TODO:` entries in committed AGENT.md files.

---

## Anti-Patterns

- Writing Lua API descriptions without consulting `src/lua_api/<module>_api.rs`
- Copying struct descriptions from a different module
- Leaving the Summary under 500 characters
- Omitting the References table (forces agents to guess dependencies)
- Describing functions that no longer exist
- Duplicating architecture facts that live in `docs/architecture/`
  (reference, don't copy)
