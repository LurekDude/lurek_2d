---
description: "Load when working with GitHub issues, PRs, labels, milestones, or roadmap mapping. Skip for CI/CD setup or code review."
alwaysApply: false
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
- Commit format is type(scope): description.
- Keep GitHub labels, milestones, issue status, and roadmap links aligned with real module ownership and actual local quality gates.
- Avoid interactive git flows in agent work; use non-interactive commands and explicit file lists.
- CONTRIBUTING.md and the current rules are the contract for process.
- Use tools/github/ only when a checked-in helper actually exists there.
- Good issue triage here includes evidence, affected module or layer, reproduction signal, and the likely validation command.
- GitHub workflow in this repo is a planning and tracking layer on top of local engineering rules.

## References
- CONTRIBUTING.md
- docs/CHANGELOG.md
- .github/
- tools/github/
