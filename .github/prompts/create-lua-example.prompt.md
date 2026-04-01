---
description: "Create a new self-contained Lua example game in examples/. Use when demonstrating a Luna2D API feature or workflow. Produces a runnable examples/<name>/main.lua."
---

# Create Lua Example

**Purpose**: Add a new runnable Lua example to `examples/` that demonstrates a specific Luna2D API capability.
**Use When**: A new API feature needs a working demo, or a tutorial use-case lacks a concrete example.
**Do Not Use When**: The example would require assets not committed to the repo, or it tests edge cases rather than typical usage.
**Scope**: `examples/` only; no `src/` changes.

## Inputs

- `EXAMPLE_NAME` — directory name, lowercase with hyphens (e.g., `particle-demo`, `audio-demo`)
- `CONCEPT` — what API feature or game mechanic this demonstrates (e.g., "keyboard-controlled movement", "physics stacking")
- `COMPLEXITY` — `simple` (< 50 lines) or `full` (< 100 lines)

## Steps

1. Load skill `lua-scripting/SKILL.md`
2. Create directory `examples/<EXAMPLE_NAME>/`
3. Write `examples/<EXAMPLE_NAME>/main.lua` with:
   - `local` variables for all state
   - `function luna.load()` — initialization
   - `function luna.update(dt)` — frame logic
   - `function luna.draw()` — rendering only
   - Optionally: `luna.keypressed`, `luna.mousepressed` callbacks
4. Check all API calls against `docs/lua_api_reference.md`:
   - Colors: `[0.0, 1.0]` float range
   - Shapes: `("fill"/"line", x, y, ...)`
   - Key names: `"space"`, `"escape"`, `"w"`, `"a"`, `"s"`, `"d"`
5. Verify it runs: `cargo run -- examples/<EXAMPLE_NAME>`
6. Add entry to README.md examples table if it demonstrates a major feature

## Outputs

- `examples/<EXAMPLE_NAME>/main.lua` — working, commented Lua script
- Any required assets in `examples/<EXAMPLE_NAME>/` (images, audio)
- Verified: `cargo run -- examples/<EXAMPLE_NAME>` opens a window without errors

## Acceptance

- [ ] Example runs with `cargo run -- examples/<EXAMPLE_NAME>`
- [ ] Uses only `luna.*` API — no external engine prefixes or undocumented functions
- [ ] All variables are `local`
- [ ] Under 100 lines (demos should be readable)
- [ ] Has comments explaining non-obvious API usage

## References

**Required Skills**: `lua-scripting`
**Suggested Agents**: `Doc-Writer`, `Developer`
**Related Prompts**: `create-game-example.prompt.md`
**Commands**:
```powershell
cargo run -- examples/<EXAMPLE_NAME>
```
**Docs**: `docs/lua_api_reference.md`, `docs/getting_started.md`
