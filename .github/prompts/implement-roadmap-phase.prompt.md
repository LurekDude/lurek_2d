---
description: "Implement work from a roadmap phase file."
---
# Implement Roadmap Phase

## Goal
- Implement the work defined in one roadmap phase file.

## Inputs
- phase_file: the roadmap phase file.

## Steps
- Load roadmap-planning, rust-coding, testing-rust, documentation, and any domain skill.
- Read the phase file and current repo state first.
- Confirm what is already done.
- Plan only the remaining work.
- Implement phase tasks in the right order.
- Run the needed tests and checks.
- Update docs and changelog when required.
- Report what is done and what is still open.

## Success Criteria
- [ ] The phase file was read first.
- [ ] Only unfinished work was implemented.
- [ ] Required checks ran.
- [ ] Phase status is clear at the end.

## Anti-patterns
- Rebuild work that already exists.
- Skip validation.
- Mix unrelated changes into the phase.
- Use git add .

## Example Invocation
- /implement-roadmap-phase phase_file

## CAG Metadata
- **Mode**: agent
- **Loads skills**: roadmap-planning, rust-coding, testing-rust, documentation
- **Inputs required**: phase_file
