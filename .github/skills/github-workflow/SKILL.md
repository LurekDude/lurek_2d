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
- Repo process expects explicit staging, one logical change per commit, and docs/CHANGELOG.md updated in the same logical change.
- Commit format is type(scope): description and branch should be checked before staging or release work.
- Keep GitHub labels, milestones, and roadmap links aligned with actual local quality gates, not a parallel process.
- Avoid interactive git flows in agent work; use non-interactive commands and explicit file lists.
- CONTRIBUTING.md and current CAG rules are the contract for process, not ad hoc PR conventions.
- Use tools/github/ only when a checked-in repo helper already exists there.
- This repo already enforces explicit staging, branch checks, and changelog discipline, so issue or PR process should reinforce those habits instead of bypassing them.
- GitHub workflow here is a planning and tracking layer on top of local quality gates, not a substitute for them.
- The skill owns labels, milestones, and change hygiene, not CI YAML or code review logic.
## Companion File Index
- None.

## References
- CONTRIBUTING.md
- docs/CHANGELOG.md
- .github/
- tools/github/
