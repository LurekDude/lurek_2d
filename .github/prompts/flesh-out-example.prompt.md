---
description: "Rewrite content/examples/<module>.lua files as scenario-driven learning examples. Each example tells a coherent story about WHEN and WHY..."
agent: Developer
tools: [tools/audit/example_coverage.py]
---
# Flesh Out Example

## Goal

Rewrite content/examples/<module>.lua files as scenario-driven learning examples. Each example tells a coherent story about WHEN and WHY... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `module` — value supplied by the user invocation.
- `name` — value supplied by the user invocation.

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md) before changing any files.
2. **NOT a one-liner + print.** The code must be 5-15 lines showing a realistic use case.
3. **NOT a test.** Do not write `if result then print("ok")`. Show the API doing real game work.
4. **Real variables.** Use game-domain names: `player_hp`, `slot1`, `walk_clip`, not `x`, `val`, `result`.
5. **Context flows between stubs.** Objects created in an earlier stub are reused in later stubs.
6. **The `--@api-stub:` marker line is NEVER removed.** Coverage counting depends on it.
7. **The original one-line docstring IS removed.** Replace it with a better contextual comment.
8. **Coverage** — every public API item is called at least once with real arguments
9. **Clarity** — a developer reading the file for the first time understands the use case
10. run: python tools/audit/example_coverage.py --module <module> --stubs
11. run: python tools/audit/example_coverage.py --module <module> --missing
12. read docs/specs/<module>.md

## Success Criteria

- [ ] All `content/examples/<module>.lua` files at 100% coverage with 0 stubs
- [ ] `python tools/audit/example_coverage.py --stubs` prints "No stub blocks remaining."
- [ ] `python tools/audit/example_coverage.py --summary` shows Stub column = 0 for all modules
- [ ] Each file has at least 3 named scenario blocks
- [ ] Reader test passes: the file reads like a short tutorial, not a function list

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/flesh-out-example <module> <name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation
- **Inputs required**: module, name
