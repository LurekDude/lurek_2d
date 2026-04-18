# SKILL TEMPLATE — `.github/skills/<name>/SKILL.md`

**Applies to**: every `SKILL.md` file under `.github/skills/<name>/`.
**Audience**: any agent that loads the skill on demand.
**Authoring agent**: CAG-Architect (with domain expert review).

---

## Hard Cap

- **≤ 120 lines** per `SKILL.md`.
- Skill folder name = frontmatter `name` exactly (kebab-case): `.github/skills/rust-coding/SKILL.md` ↔ `name: rust-coding`.

---

## Required Frontmatter (YAML, fenced with `---`)

```yaml
---
name: skill-name
description: "When to load this skill (trigger conditions). Skip it for X (skip conditions)."
companion_files:
  examples: [examples/foo.rs, examples/bar.lua]
  templates: [templates/baz.toml]
  snippets: [snippets/quick.md]
related_skills: [other-skill-1]
---
```

**Field rules**:

- `name` — kebab-case, matches folder name.
- `description` — one or two sentences. **Must contain both** a "load when …" clause and a "skip it for …" clause. The validator looks for both phrases (case-insensitive) and emits `W206` if either is missing.
- `companion_files` — three lists (`examples`, `templates`, `snippets`). All paths are **relative to the skill folder**. Any file listed must exist on disk; any file in the skill folder not listed here is allowed but unindexed.
- `related_skills` — list of other skill folder names that exist. Empty allowed.

---

## Required Body Sections (in this exact order)

1. **Mission** — one paragraph: what the skill teaches and which agent commonly loads it.
2. **When To Load** — bullet list of concrete trigger conditions.
3. **When To Skip** — bullet list of explicit skip conditions and pointers to the correct skill.
4. **Domain Knowledge** — deep prose. Conventions, decision rules, anti-patterns. **Inline `code` (single backticks) is allowed** for symbol names, file paths, and short identifiers. **Triple-backtick fences are forbidden.**
5. **Companion File Index** — a markdown list explaining what each companion file demonstrates. Reference paths in parentheses, not as fenced blocks.
6. **References** — links to `docs/specs/<module>.md`, related skills, related prompts, related agents.

---

## Forbidden Content (strict)

- **Any** triple-backtick code fence — open or close. Validator rule `E201` is a hard error and rejects the character sequence ` ``` ` anywhere in the file body. This includes language-tagged fences (` ```rust`, ` ```lua`, ` ```toml`).
- Long code listings. Move them to `examples/`, `templates/`, or `snippets/`.
- Duplicated content from `docs/specs/<module>.md` — link instead.

---

## Companion File Layout

```
.github/skills/<name>/
├── SKILL.md
├── examples/      # full runnable examples (.rs, .lua, .toml)
├── templates/     # parametric templates with placeholders
└── snippets/      # short illustrative fragments (.md or source files)
```

Companion files **may** contain code blocks, full programs, and detailed comments. The "no fenced code blocks" rule applies **only** to `SKILL.md`.

---

## Reference Implementation (compliant ~80-line skill, prose-style)

```markdown
---
name: rust-coding
description: "Load this skill when writing or reviewing Rust code in the Lurek2D engine — covers safe Rust conventions, error handling patterns, module structure, and idiomatic Rust for game engine development. Skip it for Lua scripting, CAG file authoring, or pure documentation work."
companion_files:
  examples: [examples/safe_unsafe_block.rs, examples/result_propagation.rs]
  templates: [templates/new_module_skeleton.rs]
  snippets: [snippets/clippy_allowlist.md]
related_skills: [error-handling, testing-rust, module-architecture]
---

# rust-coding

## Mission

This skill captures the Lurek2D-specific Rust conventions that go beyond rustfmt and clippy. It is most often loaded by the Developer agent and by the Renderer, Physicist, and Audio-Eng specialists when their work crosses into general engine code. The focus is on rules that a generic Rust style guide will not enforce — per-frame allocation discipline, the `SAFETY:` comment requirement, the `SlotMap`/typed-key resource pattern, and the `log!` macro family in place of `println!`.

## When To Load

- Editing or adding any file under `src/` outside the specialist surfaces.
- Reviewing a Rust diff for adherence to engine conventions.
- Bringing a new module skeleton into compliance with the tier system.

## When To Skip

- Writing Lua game scripts — load `lua-scripting` instead.
- Authoring `.github/` CAG files — load `cag-workflow` instead.
- Pure documentation in `docs/` — load `documentation` instead.

## Domain Knowledge

The single hardest convention to enforce mechanically is the per-frame allocation rule. Engine code that runs every frame must not allocate on the heap; growth-prone buffers (draw command queues, particle pools, sprite batch slots) are sized at startup and reused via `SlotMap` keyed by typed handles defined in `src/runtime/resource_keys.rs`. A push to a per-frame buffer that triggers `Vec::reserve` is a defect even if it does not show up in clippy.

`unsafe` blocks always carry a `// SAFETY:` comment naming the invariant that makes the block sound. Raw pointers are never used to share state between threads or between Rust and Lua — channels (`crate::thread::Channel`) and `Rc<RefCell<SharedState>>` are the only sanctioned mechanisms.

Logging follows the `log` crate facade: `log::info!` for lifecycle, `log::warn!` for degraded recoveries, `log::error!` for unrecoverable frame errors, `log::debug!` for per-frame detail. `println!` is forbidden in engine code (it bypasses the `RUST_LOG` filter and the embedded log capture used by tests). The split between `error!` and `panic!` matters — engine code should propagate `Result` and let `app::run` decide whether to surface the failure as a frame skip or a hard exit.

## Companion File Index

- examples/safe_unsafe_block.rs — illustrates the `// SAFETY:` comment requirement on a `slice::from_raw_parts` call inside the texture upload path.
- examples/result_propagation.rs — shows the typical `EngineError -> LuaError` conversion at the binding boundary.
- templates/new_module_skeleton.rs — a starter file with the canonical `//!` module docstring, public re-exports, and a `#[cfg(test)] mod tests` stub.
- snippets/clippy_allowlist.md — the small set of `#[allow(...)]` lints that are accepted in engine code, with rationale per entry.

## References

- docs/specs/runtime.md — `SlotMap` and typed-key contract.
- .github/skills/error-handling/SKILL.md — full `EngineError` matrix.
- .github/skills/testing-rust/SKILL.md — how to test code written under this skill.
- .github/agents/developer.agent.md — primary loader.
```

---

## Validator Rules Summary

| Rule  | Severity | Description                                                                                |
|-------|----------|--------------------------------------------------------------------------------------------|
| E201  | error    | Triple-backtick fenced code block detected anywhere in `SKILL.md` body.                    |
| E202  | error    | Missing or malformed YAML frontmatter.                                                     |
| E203  | error    | `companion_files` references a path that does not exist under the skill folder.            |
| E204  | error    | `related_skills` references a skill folder that does not exist.                            |
| E205  | error    | Missing one of the 6 required body sections (in correct order).                            |
| W206  | warning  | `description` does not include both a load-trigger clause and a skip clause.               |
