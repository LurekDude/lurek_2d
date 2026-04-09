---
description: "Create a new self-contained Lua example game in content/examples/. Use when demonstrating a Lurek2D API feature or workflow. Produces a runnable content/content/examples/<name>/main.lua."
---

# Create Lua Example

**Purpose**: Add a new runnable Lua example to `content/content/examples/` that demonstrates a specific Lurek2D API capability.
**Use When**: A new API feature needs a working demo, or a tutorial use-case lacks a concrete example.
**Do Not Use When**: The example would require assets not committed to the repo, or it tests edge cases rather than typical usage.
**Scope**: `content/content/examples/` only; no `src/` changes.

## Inputs

- `EXAMPLE_NAME` — directory name, lowercase with hyphens (e.g., `particle-demo`, `audio-demo`)
- `CONCEPT` — what API feature or game mechanic this demonstrates (e.g., "keyboard-controlled movement", "physics stacking")
- `COMPLEXITY` — `simple` (< 50 lines) or `full` (< 100 lines)

## Steps

1. Load skill `lua-scripting/SKILL.md`
2. Create directory `content/content/examples/<EXAMPLE_NAME>/`
3. Write `content/content/examples/<EXAMPLE_NAME>/main.lua` with:
   - `local` variables for all state
   - `function lurek.init()` — initialization
   - `function lurek.process(dt)` — frame logic
   - `function lurek.render()` — rendering only
   - Optionally: `lurek.keypressed`, `lurek.mousepressed` callbacks
4. Check all API calls against `docs/API/lua_api_reference_generated.md`:
   - Colors: `[0.0, 1.0]` float range
   - Shapes: `("fill"/"line", x, y, ...)`
   - Key names: `"space"`, `"escape"`, `"w"`, `"a"`, `"s"`, `"d"`
5. Verify it runs: `cargo run -- content/content/examples/<EXAMPLE_NAME>`
6. Add entry to README.md examples table if it demonstrates a major feature

## Outputs

- `content/content/examples/<EXAMPLE_NAME>/main.lua` — working, commented Lua script
- Any required assets in `content/content/examples/<EXAMPLE_NAME>/` (images, audio)
- Verified: `cargo run -- content/content/examples/<EXAMPLE_NAME>` opens a window without errors

## Acceptance

- [ ] Example runs with `cargo run -- content/content/examples/<EXAMPLE_NAME>`
- [ ] Uses only `lurek.*` API — no external engine prefixes or undocumented functions
- [ ] All variables are `local`
- [ ] Under 100 lines (demos should be readable)
- [ ] Has comments explaining non-obvious API usage

## References

**Required Skills**: `lua-scripting`
**Suggested Agents**: `Doc-Writer`, `Developer`
**Related Prompts**: `create-game-example.prompt.md`
**Commands**:
```powershell
cargo run -- content/content/examples/<EXAMPLE_NAME>
```
