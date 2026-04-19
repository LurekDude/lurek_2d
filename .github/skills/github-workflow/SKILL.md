---
name: github-workflow
description: "Load this skill when working with Lurek2D's GitHub project: creating or triaging issues, opening PRs, managing labels and milestones, using mcp_github_* tools for automation, or mapping roadmap phases to GitHub milestones. Skip it for CI/CD pipeline configuration (use ci-cd-pipeline skill) or code review (use Reviewer agent)."
---
# github-workflow

## Mission

# GitHub Workflow — Lurek2D

## When To Load

- Creating, triaging, or closing GitHub issues for Lurek2D
- Opening or merging pull requests
- Using `mcp_github_*` tools to search, read, or update issues/PRs
- Mapping roadmap phases to GitHub milestones
- Understanding the label taxonomy and project conventions
- Preparing a release tag and changelog

## When To Skip

- Skip it for CI/CD pipeline configuration (use ci-cd-pipeline skill) or code review (use Reviewer agent).

## Domain Knowledge

### Owns
- GitHub label taxonomy and issue type conventions
- Branch naming patterns and PR process rules
- Roadmap phase ↔ GitHub milestone mapping
- `mcp_github_*` tool usage patterns for Lurek2D
- Git commit message format (`type(scope): description`)
- Release tagging and packaging process

### Issue Types and Labels
| Label prefix | Meaning | Examples |
|---|---|---|
| `type:` | Issue category | `type:bug`, `type:feature`, `type:docs`, `type:task` |
| `module:` | Affected source module | `module:graphics`, `module:physics`, `module:lua_api` |
| `tier:` | Architecture tier | `tier:1`, `tier:2`, `tier:3` |
| `priority:` | Urgency | `priority:critical`, `priority:high`, `priority:low` |
| `status:` | Work state | `status:blocked`, `status:ready`, `status:in-review` |
| `phase:` | Roadmap phase | `phase:4`, `phase:5` |

### Branch Naming Convention
> See [snippets/branch-naming-convention.txt](snippets/branch-naming-convention.txt) for the example.

| Type | Use for |
|---|---|
| `feat/` | New feature or module |
| `fix/` | Bug fix |
| `refactor/` | Code restructure (no behavior change) |
| `docs/` | Documentation-only change |
| `test/` | Tests only |
| `chore/` | Build scripts, deps, tooling |

### Pull Request Process
1. Branch from `main`; never commit directly to `main`
2. One logical change per PR (one roadmap task = one PR)
3. PR title: same as commit format — `type(scope): description`
4. Must pass all quality gates before merge:
   - `cargo test && cargo clippy -- -D warnings`
   - `cargo fmt --check`
   - `python tools/docs/collect_docs.py --report-missing`
5. Request review via `mcp_github_pull_request_review_write` or GitHub UI
6. Squash-merge to main — keep main history clean

### Roadmap ↔ GitHub Milestones
| Roadmap phase | Milestone name | Purpose |
|---|---|---|
| Phase 1–3 | `v0.1–v0.3` (historical) | Foundation and core API |
| Phase 4 | `v0.4` | Current active phase |
| Phase 5+ | `v0.5+` | Future phases |

Map roadmap acceptance gates to GitHub issue completion to track phase progress automatically.

### Using mcp_github_* Tools
Key tool patterns for Lurek2D work:

> See [snippets/using-mcpgithub-tools.txt](snippets/using-mcpgithub-tools.txt) for the example.

Always search before creating — avoid duplicate issues.

### Git Commit Convention
> See [snippets/git-commit-convention.txt](snippets/git-commit-convention.txt) for the example.

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Non-behavioral change |
| `test` | Test additions or fixes |
| `docs` | Documentation only |
| `chore` | Build system, deps, tooling |

Scope = affected module or area: `graphics`, `physics`, `lua_api`, `cag`, `docs`.

**Rules:**

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/branch-naming-convention.txt](snippets/branch-naming-convention.txt) — Branch Naming Convention
- [snippets/using-mcpgithub-tools.txt](snippets/using-mcpgithub-tools.txt) — Using mcp_github_* Tools
- [snippets/git-commit-convention.txt](snippets/git-commit-convention.txt) — Git Commit Convention
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
