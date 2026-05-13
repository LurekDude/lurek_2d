---
description: "Audit and complete Rust docs in src/<module>/ by following rust-coding skill rules as the single source of truth, then verify with quality checks."
agent: "Developer"
---
# Workflow: Document Rust Module

## Goal
- Every `.rs` file in `src/<module>/` (including `mod.rs`) follows the active doc rules from `../skills/rust-coding/SKILL.md`.
- Every file-level `//!` doc is a compact technical summary of the file's role, up to about 600 characters, wrapped across short readable lines when needed, and must not duplicate the `pub` items or re-list what the file already declares.
- Specifically: remove all AI-generated prose, synonym inflation, and synthetic phrases ("incurs no allocation", "alias for", "placeholder", "O(1) amortised", "call it freely in hot paths", "returns a fully initialised instance", etc.).
- Replace with concrete technical one-liners in imperative form ("Return", "Parse", "Read", not "Returns", "Parses", "Reads").
- All `#[cfg(test)]` blocks are moved out to `tests/rust/unit/<module>_<file>_tests.rs`.
- `cargo check` and `cargo clippy -- -D warnings` pass after the work is complete.

## Inputs
- `module` — the module directory to process (e.g. `physics`, `render`, `audio`).

## Documentation Standard Source
- Single source of truth: `../skills/rust-coding/SKILL.md`.
- Do not restate or override style rules in this prompt.
- If this prompt and the skill disagree, the skill wins.

## Required Non-style Rules
For every file in `src/<module>/` that has inline tests:
1. Extract the full `mod tests { ... }` block.
2. Create `tests/rust/unit/<module>_<file>_tests.rs`.
3. Adjust imports: replace `use super::*;` with explicit imports from the crate root using `use lurek2d::<module>::...;`.
4. Delete the extracted block from the source file.
5. If the repo has a unit-test registry module, add `pub mod <module>_<file>_tests;` there.

For every `mod.rs` in scope:
- Keep only `pub mod`, `pub use`, attributes, and module docs.
- Move any definitions to sibling files and re-export from `mod.rs`.

## Steps

1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md) and [skill: documentation](../skills/documentation/SKILL.md) before acting.

2. **Inventory pass** — For every `.rs` file in `src/<module>/` (include `mod.rs`):
   - Check docs against current `rust-coding` skill rules only.
   - Check: does it have `#[cfg(test)]`?
   - Check: list items missing required docs per skill.
   - Record findings in a table: `File | Skill-doc gaps | Has tests | Test-move needed`.

3. **Fix tests first** — Extract all `#[cfg(test)]` blocks from source files, create the corresponding `tests/rust/unit/` files, and update `mod.rs` registration. Verify `cargo check` still passes before continuing.

4. **File-by-file doc pass** — For each file with findings from step 2 (including `mod.rs`):
   a. Apply exactly the active style from `rust-coding` skill.
   b. Do not add local style inventions or legacy formats.
   c. Keep edits minimal and deterministic.

5. **Verify** — Run `cargo check` and `cargo clippy -- -D warnings`. Fix any warning introduced by the documentation changes (e.g. broken intra-doc links, `rustdoc::broken_intra_doc_links`).

6. **Report** — Return a table:
   `File | Skill-doc status | Tests moved | Issues remaining`
   Any remaining issue must be listed with the exact file, line, and reason it could not be fixed.

## Success Criteria
- [ ] Every `.rs` file in `src/<module>/` including `mod.rs` follows current `rust-coding` skill doc rules.
- [ ] Zero `#[cfg(test)]` blocks remain in `src/<module>/`.
- [ ] `cargo check` passes with zero errors.
- [ ] `cargo clippy -- -D warnings` passes with zero warnings.

## Anti-patterns
- Reintroducing local style rules that duplicate or conflict with `rust-coding` skill.
- Leaving `#[cfg(test)]` in place and only adding docs around it.
- Inventing doc content that contradicts the implementation.
- Adding `// TODO`, `// FIXME`, or `// HACK` markers as part of this task — those belong in a separate issue.
- Touching files outside `src/<module>/` or `tests/rust/unit/`.

## Example Invocation
- `/workflow-document-rust-module module=physics`
- `/workflow-document-rust-module module=render`
- `/workflow-document-rust-module module=audio`

## CAG Metadata
Mode: agent
Loads skills: rust-coding, documentation
Inputs required: Target module directory name (e.g. physics, render, audio).
