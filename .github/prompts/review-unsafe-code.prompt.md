---
description: "Review unsafe code blocks: verify SAFETY comments and justification for every unsafe usage."
mode: agent
loads_skills: [rust-coding]
loads_tools: []
expected_agent: Security
inputs_required: []
---

# Review Unsafe Code

## Goal

Audit all `unsafe` blocks for proper justification and safety.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Search for all `unsafe` blocks in `src/`
3. For each: verify `// SAFETY:` comment exists immediately above
4. Evaluate if `unsafe` is truly necessary (safe alternative available?)
5. Check that safety invariants are correctly maintained
6. Report unjustified or unnecessary `unsafe` usage

## Success Criteria

- [ ] All `unsafe` blocks have `// SAFETY:` comments
- [ ] Each use of `unsafe` is genuinely necessary
- [ ] Safety invariants documented and upheld

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-unsafe-code`
