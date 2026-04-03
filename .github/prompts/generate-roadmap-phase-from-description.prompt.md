---
description: "Turn any free-text feature description into a complete, production-ready docs/roadmap/phase-NN-*.md file. Multi-step analysis: parse intent → explore codebase → compare actual state → write full phase document."
name: "Generate Roadmap Phase from Description"
---

# Generate Roadmap Phase from Description

You will turn the user-provided feature description into a single, fully detailed `docs/roadmap/phase-NN-*.md` file that exactly matches the Luna2D roadmap format.

**Load skill first**: read `.github/skills/roadmap-planning/SKILL.md` before writing anything.

---

## Input

The feature description provided by the user (argument or pasted text). It may be:
- A rough idea in any language
- A structured spec
- A bullet list of capabilities
- An excerpt copied from another engine's docs
- A mix of all the above

One description = one phase file.

---

## Analysis Pipeline

Work through every stage in order. Do not skip stages or merge them.

### Stage 1 — Intent Extraction

Read the description carefully and extract:

1. **Feature domain** — which Luna2D module(s) does this touch? (graphics, physics, audio, input, filesystem, math, timer, window, data, image, sound, event, thread, system, or a new module)
2. **Core capability** — one sentence: what can the game developer do after this phase that they cannot do today?
3. **Scope signal** — is this a small addition (1–3 new functions), a medium module extension (new sub-system), or a large new module (brand-new `src/<name>/` + `lua_api/<name>_api.rs`)?
4. **Lua API surface sketch** — list the `luna.*` function names implied by the description. If none are named, invent canonical names following the `luna.<module>.<verb><Noun>` pattern.
5. **Rust implementation surface sketch** — list the struct/trait/module names the implementation will likely need.

Output a short internal analysis block (not part of the final file). Use this format:

```
[INTENT]
Domain       : <module name(s)>
Core cap     : <one sentence>
Scope        : Small | Medium | Large
Lua API      : luna.X.foo(), luna.X.bar(), ...
Rust surface : StructName, fn_name, mod name
```

### Stage 2 — Codebase State Audit

For each domain module identified in Stage 1, explore the repository and build a precise picture of current state.

**Search steps** (run all that are relevant):

```
list_dir src/<domain>/
list_dir src/lua_api/
grep_search "luna.<module>" in src/lua_api/
grep_search "<StructName>" in src/
file_search **/<slug>*.rs
```

For each relevant source file found, read its public API surface (structs, pub fn signatures, Lua method registrations).

Also check:
- `docs/API/lua_api_reference_generated.md` — what the current generated reference says
- Any related roadmap phase already in `docs/roadmap/` that touches the same domain

Build two lists:

**Already implemented** — functions/structs that exist and work today:
```
✅  luna.X.foo()        →  FooImpl::new()          src/X/foo.rs:42
✅  luna.X.bar()        →  BarStruct               src/lua_api/x_api.rs:88
```

**Missing / gaps** — things described but not present in the codebase:
```
❌  luna.X.baz()        →  Not found anywhere
❌  luna.X.qux(a, b)    →  Partial: struct exists but no Lua binding
```

### Stage 3 — Phase Numbering and Metadata

1. Run `list_dir docs/roadmap/` to find the current highest phase number.
2. Assign the next number (zero-padded, e.g. `19`, `20`).
3. Choose a slug: lowercase-hyphenated, max 4 words, describes the feature not the status.
4. Determine dependencies:
   - Does this phase need SlotMap keys? → Depends On Phase 1
   - Does it need OO Lua objects (UserData)? → Depends On Phase 13
   - Does it introduce a new module used by other phases? → mark Blocks accordingly
   - Scan existing phases' `Blocks:` fields to find any that list this feature area
5. Assign priority:
   - **Critical** — engine cannot function correctly without this
   - **High** — most games are blocked without this; visible capability gap
   - **Medium** — advanced games need it; not day-one requirement
   - **Low** — niche, experimental, or long-term target

### Stage 4 — Implementation Tasks Decomposition

Break the work into numbered sub-tasks `N.1`, `N.2`, `N.3` …

For each sub-task:

- **Title** — imperative verb phrase ("Add X", "Implement Y Lua binding", "Expose Z via UserData")
- **File(s)** — exact paths relative to workspace root. For new files, state they are new. For modified files, confirm they exist (use the audit from Stage 2).
- **Description** — what to build. When the data shape is non-obvious, include:
  - A Rust struct/enum snippet showing the proposed type signature
  - A Lua API snippet showing the exact `luna.*` calls and return types
- **Agent** — which specialist implements this task:
  - `Developer` — general Rust/engine work
  - `Renderer` — all `src/graphics/` code
  - `Physicist` — all `src/physics/` code
  - `Audio-Eng` — all `src/audio/` or `src/sound/` code
  - `Tester` — test files only
  - `Doc-Writer` — documentation only

Minimum sub-tasks for any phase:
- At least one Rust implementation task
- At least one Lua binding task (unless the phase is purely internal)
- At least one test task

### Stage 5 — Acceptance Gates

Write binary pass/fail acceptance gates. Every gate must be independently verifiable by running a command or reading a file — no subjective criteria.

Required gates (adapt to phase specifics):
1. `cargo build` succeeds with no errors
2. `cargo test` passes (or specific test module: `cargo test <module>_tests`)
3. Named Lua example exercises the new API end-to-end (state the filename)
4. `cargo clippy -- -D warnings` produces zero warnings
5. Any feature-specific observable: a rendered output, a returned value, a log line

---

## Output

Write the complete phase file to `docs/roadmap/phase-{NN}-{slug}.md`.

Follow the format from `.github/skills/roadmap-planning/SKILL.md` exactly. Every section is mandatory unless explicitly marked optional in the skill. Reproduce the exact heading hierarchy (`## Goal`, `## Current State Analysis`, `## Implementation Tasks`, `## Acceptance Gates`).

The file must be self-contained: a developer with no prior context who reads only the phase file must be able to understand what to build, what already exists, which files to touch, and how to verify completion.

**Quality bar**: The file should match the detail level of `docs/roadmap/phase-01-core-engine-hardening.md` and `docs/roadmap/phase-14-thread-module.md` — both include Rust struct snippets, Lua API tables, gap analysis tables, and numbered acceptance gates.

---

## Post-Write Checklist

After saving the file, verify:

- [ ] Phase number is unique (not reusing an existing number)
- [ ] Slug is lowercase-hyphenated and ≤ 4 words
- [ ] All file paths in Implementation Tasks exist in the repo OR are marked as new files
- [ ] `Depends On` references are accurate (open each referenced phase file to confirm it exists)
- [ ] `Blocks` field is updated in any phase that this new phase enables
- [ ] No `luna.` prefix replaced with any external engine prefix anywhere in the file
- [ ] Acceptance gates are all binary (pass/fail), not subjective

Report any checklist failures as warnings after saving.

---

## Clarifications (User Session Rules)

- **Process one feature at a time.** When given multiple features, complete each phase file fully before starting the next. Do not load all input descriptions simultaneously. Focus on one, finish it, then move to the next.
- **Extract exhaustively.** Capture every method, function, enum, type, and constant from the input description. Do not summarize or skip "obvious" items. Every single function signature, enum value, and type must be documented in the phase file.
- **Module placement matters.** If a feature logically belongs inside an existing module (e.g. pathfinding → `math` or `ai`), place it there instead of creating a standalone module. Justify the placement decision in the phase file.
- **Detect duplicates.** Before writing tasks, check if the described feature (or parts of it) already exists in the codebase. If it does, report the overlap in the `## Current State Analysis` section with exact file paths and function names. Do not blindly create tasks for already-implemented functionality — report what already exists.
- **Entity/ECS validation.** When the input mentions entities, validate the entire entity system status in the codebase and report findings.
- **All methods documented.** Every function/method from the input description must appear in the Implementation Tasks — either as a task to implement or as a note that it already exists. No method should be silently dropped.
- **Do not assume — verify.** Use subagents to deeply understand what is planned vs what is missing vs what is already implemented. Never guess the codebase state.
- **Report overlaps honestly.** If a feature (or part of it) already exists elsewhere in the system, report it in the roadmap file. Do not duplicate tasks for already-implemented functionality just because the input description says so.
- **Maximum extraction.** When the input is a reference document (e.g., from another engine), extract EVERYTHING — all methods, all parameters, all return types, all enums, all constants. The goal is zero information loss from input to phase file.
