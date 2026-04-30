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
- Repo process expects explicit staging, one logical change per commit, and docs/CHANGELOG.md updated in the same logical change, so GitHub workflow should reinforce that structure rather than hide it behind broad PRs.
- Commit format is type(scope): description, and the current branch should be checked before staging, release work, or milestone updates so history stays attributable.
- Keep GitHub labels, milestones, issue status, and roadmap links aligned with real module ownership and actual local quality gates, not a parallel planning vocabulary.
- Avoid interactive git flows in agent work; use non-interactive commands, explicit file lists, and concrete status output that another contributor can reproduce.
- CONTRIBUTING.md and the current CAG rules are the contract for process, not ad hoc PR folklore or personal branch habits.
- Use tools/github/ only when a checked-in helper actually exists there; do not assume missing automation and invent process requirements that the repo does not support.
- Good issue triage here includes evidence, affected module or layer, reproduction signal, and the likely validation command, not just a feature request title.
- Good PR hygiene here includes a narrow scope, visible validation, synced docs or changelog updates when required, and labels that help route follow-up work.
- GitHub workflow in this repo is a planning and tracking layer on top of local engineering rules, not a substitute for tests, docs sync, or packaging checks.
- Milestones should represent deliverable slices with real gates and owners; vague buckets that do not map to repo work quickly become stale.
- This skill owns labels, milestones, issue and PR structure, and change hygiene, not CI YAML, implementation details, or code review findings themselves.
## Companion File Index
- None.

## References
- CONTRIBUTING.md
- docs/CHANGELOG.md
- .github/
- tools/github/
