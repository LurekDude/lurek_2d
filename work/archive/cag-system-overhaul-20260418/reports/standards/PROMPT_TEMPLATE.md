# PROMPT TEMPLATE — `.github/prompts/<verb>-<noun>.prompt.md`

**Applies to**: every prompt file under `.github/prompts/`.
**Audience**: end users picking from the prompt list, plus the routed agent that executes the prompt.
**Authoring agent**: CAG-Architect (with Doc-Writer review for link integrity).
**Aligned with Claude Code prompt best practices**: clear role, tools/skills declared upfront, success criteria binary, anti-patterns explicit.

---

## Naming

- Filename: `<verb>-<noun>.prompt.md` — verb first, kebab-case, e.g. `create-tilemap-feature.prompt.md`, `fix-failing-tests.prompt.md`.
- Approved verb prefixes: `create-`, `fix-`, `review-`, `analyze-`, `implement-`, `run-`, `workflow-`, `doc-`.

---

## Required Frontmatter (YAML, fenced with `---`)

```yaml
---
description: "One-line task description (shown in the prompt picker)."
mode: agent
loads_skills: [skill-name-1, skill-name-2]
loads_tools: [tools/foo.py]
expected_agent: Developer
inputs_required: [arg1, arg2]
---
```

**Field rules**:

- `description` — one sentence, ≤ 120 characters, ends with a period.
- `mode` — one of `agent` (default routing), `ask` (no agent, just a chat), or a specific agent `name` like `Developer` to bypass routing.
- `loads_skills` — list of skill folder names; each must exist under `.github/skills/<name>/`.
- `loads_tools` — list of repo-relative paths under `tools/`; each must exist on disk.
- `expected_agent` — name of an agent in `.github/agents/`. Used by the validator to verify the agent's `routes_to` graph can reach this prompt's responsibilities. `Manager` is valid for prompts that spawn a multi-agent session.
- `inputs_required` — list of argument names the prompt expects from the user invocation. Empty allowed.

---

## Required Body Sections (in this exact order)

1. **Goal** — one paragraph naming the desired end state. Must be concrete enough that "done" is unambiguous.
2. **Inputs** — bullet list mirroring `inputs_required` from frontmatter, with one-line description per input.
3. **Steps** — numbered (3–12). **Every step that uses a tool or skill must reference it via markdown link** using the canonical syntax below.
4. **Success Criteria** — binary checklist (markdown task list `- [ ]`). Each item is independently checkable. **At least 1 item required**; warning if zero.
5. **Anti-patterns** — bullet list of common mistakes the executing agent should avoid for this specific task.
6. **Example Invocation** — short example showing how a user would invoke the prompt with sample inputs.

---

## Reference Syntax for Cross-References

| Target type | Syntax                                                                  |
|-------------|-------------------------------------------------------------------------|
| Skill       | `[skill: name](.github/skills/name/SKILL.md)`                           |
| Tool        | `[tool: name](tools/path/script.py)`                                    |
| Other prompt| `[prompt: name](.github/prompts/name.prompt.md)`                        |
| Agent       | `[agent: Name](.github/agents/name.agent.md)`                           |
| Spec        | `[spec: module](docs/specs/module.md)`                                  |

---

## Reference Implementation (compliant ~60-line `create-tilemap-feature.prompt.md`)

```markdown
---
description: "Add a new feature to the tilemap module: Rust implementation, Lua API binding, spec update, example, and tests."
mode: agent
loads_skills: [rust-coding, lua-rust-bridge, lua-api-design, testing-rust]
loads_tools: [tools/validate/cag_validate.py, tools/docs/gen_docs_lua.py, tools/audit/example_coverage.py]
expected_agent: Developer
inputs_required: [feature_name, behavior_description]
---

# create-tilemap-feature

## Goal

Add a new tilemap feature to Lurek2D end-to-end: pure-Rust logic in `src/tilemap/`, Lua binding in `src/lua_api/tilemap_api.rs`, contract update in `docs/specs/tilemap.md`, runnable usage in `content/examples/tilemap.lua`, and passing tests under `tests/rust/unit/tilemap_*` and `tests/lua/unit/test_tilemap_*.lua`. The feature ships only when `cargo test`, `cargo clippy -- -D warnings`, and `python tools/validate/cag_validate.py` all return zero errors.

## Inputs

- `feature_name` — the kebab-case name of the new feature (e.g. `auto-tile-rules`).
- `behavior_description` — 2–4 sentence description of what the feature does and what calls it.

## Steps

1. Read [spec: tilemap](docs/specs/tilemap.md) to understand the current contract.
2. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md) and [skill: lua-rust-bridge](.github/skills/lua-rust-bridge/SKILL.md).
3. Implement the pure-Rust logic in `src/tilemap/` — no `mlua` imports.
4. Following [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), add the Lua binding to `src/lua_api/tilemap_api.rs` only.
5. Update `docs/specs/tilemap.md` with the new function/method and parameters.
6. Add a usage example to `content/examples/tilemap.lua`.
7. Following [skill: testing-rust](.github/skills/testing-rust/SKILL.md), add Rust unit tests and at least one Lua BDD test (registering it in `tests/lua/harness.rs`).
8. Run [tool: cag_validate](tools/validate/cag_validate.py) and [tool: example_coverage](tools/audit/example_coverage.py) `--module tilemap`.
9. Regenerate Lua API docs with [tool: gen_docs_lua](tools/docs/gen_docs_lua.py).
10. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] `cargo test` passes.
- [ ] `cargo clippy -- -D warnings` passes.
- [ ] `python tools/validate/cag_validate.py` returns 0 errors.
- [ ] `python tools/audit/example_coverage.py --module tilemap` shows the new API covered.
- [ ] `docs/specs/tilemap.md` documents the new function with parameters and return type.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Putting `impl LuaUserData` in `src/tilemap/` — it belongs in `src/lua_api/tilemap_api.rs`.
- Skipping the Lua test (Rust-only test coverage of a Lua-reachable API is a blocking defect).
- `git add .` — stage only the files this prompt produced.

## Example Invocation

> Run prompt `create-tilemap-feature` with `feature_name=auto-tile-rules` and `behavior_description="Replace placeholder tiles with neighbour-aware variants when the map is built."`
```

---

## Validator Rules Summary

| Rule  | Severity | Description                                                                       |
|-------|----------|-----------------------------------------------------------------------------------|
| E301  | error    | Missing or malformed YAML frontmatter.                                            |
| E302  | error    | `loads_skills` references a skill folder that does not exist.                     |
| E303  | error    | `loads_tools` references a path that does not exist on disk.                      |
| E304  | error    | `expected_agent` references an agent name that does not exist.                    |
| E305  | error    | Missing one of the 6 required body sections (in correct order).                   |
| W306  | warning  | Success Criteria section has zero checklist items.                                |
