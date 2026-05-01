---
name: github-workflow
description: "Load this skill when working with GitHub issues, PRs, labels, milestones, or roadmap mapping. Skip it for CI/CD setup or code review."
---
# github-workflow

## Mission
- Own GitHub issue, PR, label, and milestone workflow guidance.

## When To Load
- Triage issues.
- Prepare or review PR workflow details.
- Map roadmap work to milestones.
- Use repo GitHub automation tools.

## When To Skip
- CI workflow setup.
- Code review work.

## Domain Knowledge
- Commit format is `type(scope): description`. Allowed types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. Scope is the primary module or layer (e.g., `physics`, `lua-api`, `cag`, `ci`). Description is present tense, no period. Every commit that changes behavior must include a `docs/CHANGELOG.md` update in the same commit — never in a follow-up cleanup commit.
- How to stage a commit correctly: `git status` to see dirty files, `git diff --stat HEAD` to confirm what changed, then `git add <each file explicitly>`. Never `git add .`. Confirm the branch with `git rev-parse --abbrev-ref HEAD` before staging anything. If the branch is `main`, ask the user before proceeding.
- PR scoping rule: one PR, one logical change. Mixed PRs (feature + bug fix + refactor) are hard to review and hard to revert. If a PR touches more than 3 unrelated files or more than 2 module groups, split it. The exception is cross-artifact sync — a single API change that requires updating spec, example, and changelog is one logical change.
- How to use milestones: a milestone represents a deliverable slice with an explicit acceptance gate. The gate must be a runnable check (e.g., `cargo test`, specific audit command, screenshot comparison). Milestones without a gate become backlogs. When creating a milestone, write the gate in its description field.
- How to triage an issue: add a `module:` label to identify the affected subsystem. Add a `type:` label (bug, enhancement, task, question). Add a `persona:` label (EngDev, GameDev, Modder) to indicate who is affected. For bugs, add a `repro:` section in the issue body with the exact command and failing output. Issues without a repro command are hard to assign.
- How to label a PR for routing: `needs-review` when ready for human review; `blocked` when waiting on another PR or external decision; `auto-merge` only when all quality gates pass. The `cag` label routes to the CAG-Architect agent; the `engine` label routes to the Developer agent.
- `CONTRIBUTING.md` is the canonical process document. When a process question arises, check there first. If the answer is not there, add it after resolving the question — the answer belongs in `CONTRIBUTING.md`, not in a chat message.
## Companion File Index
- None.

## References
- CONTRIBUTING.md
- docs/CHANGELOG.md
- .github/
- tools/github/
