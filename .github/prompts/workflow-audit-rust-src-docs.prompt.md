---
description: "Audit and fix Rust docs across src/ excluding src/lua_api by reading each file fully, editing one file at a time, and writing feature-based file headers."
agent: "developer"
---
# Workflow: Audit Rust Src Docs

## Goal
- Complete a manual Rust doc audit for `src/` excluding `src/lua_api/`, with accurate item docs and feature-based file headers.

## Inputs
- Start folder or current resume point.
- Optional stop boundary such as file count, module count, or end folder.
- Any user-imposed language or formatting override.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md) and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Traverse `src/` in strict alphabetical order by folder, then by file, and skip `src/lua_api/` completely.
3. Work on exactly one `.rs` file at a time and read the whole file before writing any doc change.
4. Audit every Rust item in that file and keep, fix, or add one-line docs only when they match the real code exactly.
5. Add or fix the top-level `//!` doc only after the full file audit, and make it a compact multiline bullet list of real file features, owned responsibilities, and architectural purpose derived from the whole file.
6. Keep the file header free of dependency notes, method inventories, symbol-by-symbol summaries, and repeated templates such as `defines`, `owns`, or `keeps`.
7. Size the file header to the file: about 300-400 characters for small files, 600-800 for medium files, and up to about 1200 for large files when the feature surface requires it.
8. After each edited file, run the narrowest validation for that file, fix any doc mistake introduced by the edit, and only then move to the next file.
9. Do not use subagents, helper scripts, or batch generation for the writing itself; perform the audit manually file by file until the requested stop boundary is reached.

## Success Criteria
- [ ] The workflow outcome is complete: manual Rust doc audit for `src/` excluding `src/lua_api/`, with accurate item docs and feature-based file headers.
- [ ] Files were processed in strict alphabetical order, one file at a time.
- [ ] Every touched file was read fully before editing.
- [ ] Each touched file has accurate one-line item docs and a feature-based `//!` header derived from the whole file.
- [ ] Each touched file was validated immediately after editing.

## Anti-patterns
- Skim the header or first page of a file and write docs from partial context.
- Invent behavior, add filler, or smooth over uncertainty with generic prose.
- Use a repeated header template instead of a real feature list for the current file.
- List methods, structs, or dependencies instead of describing the file's actual owned features.
- Edit several files first and postpone validation until later.
- Use subagents, scripts, or batch automation to generate the docs.

## Example Invocation
- /workflow-audit-rust-src-docs start=src/ai
- /workflow-audit-rust-src-docs start=src/animation stop=10-files
- /workflow-audit-rust-src-docs start=src/app stop=src/debugbridge

## CAG Metadata
Mode: agent
Loads skills: rust-coding, documentation
Inputs required: Start folder or current resume point., Optional stop boundary such as file count, module count, or end folder., Any user-imposed language or formatting override.
