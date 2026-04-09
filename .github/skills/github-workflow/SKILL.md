---
name: github-workflow
description: "Load this skill when working with Lurek2D's GitHub project: creating or triaging issues, opening PRs, managing labels and milestones, using mcp_github_* tools for automation, or mapping roadmap phases to GitHub milestones. Skip it for CI/CD pipeline configuration (use ci-cd-pipeline skill) or code review (use Reviewer agent)."
---

# GitHub Workflow — Lurek2D

## Load When

- Creating, triaging, or closing GitHub issues for Lurek2D
- Opening or merging pull requests
- Using `mcp_github_*` tools to search, read, or update issues/PRs
- Mapping roadmap phases to GitHub milestones
- Understanding the label taxonomy and project conventions
- Preparing a release tag and changelog

## Owns

- GitHub label taxonomy and issue type conventions
- Branch naming patterns and PR process rules
- Roadmap phase ↔ GitHub milestone mapping
- `mcp_github_*` tool usage patterns for Lurek2D
- Git commit message format (`type(scope): description`)
- Release tagging and packaging process

## Issue Types and Labels

| Label prefix | Meaning | Examples |
|---|---|---|
| `type:` | Issue category | `type:bug`, `type:feature`, `type:docs`, `type:task` |
| `module:` | Affected source module | `module:graphics`, `module:physics`, `module:lua_api` |
| `tier:` | Architecture tier | `tier:1`, `tier:2`, `tier:3` |
| `priority:` | Urgency | `priority:critical`, `priority:high`, `priority:low` |
| `status:` | Work state | `status:blocked`, `status:ready`, `status:in-review` |
| `phase:` | Roadmap phase | `phase:4`, `phase:5` |

## Branch Naming Convention

```
type/short-description
```

| Type | Use for |
|---|---|
| `feat/` | New feature or module |
| `fix/` | Bug fix |
| `refactor/` | Code restructure (no behavior change) |
| `docs/` | Documentation-only change |
| `test/` | Tests only |
| `chore/` | Build scripts, deps, tooling |


## Pull Request Process

1. Branch from `main`; never commit directly to `main`
2. One logical change per PR (one roadmap task = one PR)
3. PR title: same as commit format — `type(scope): description`
4. Must pass all quality gates before merge:
   - `cargo test && cargo clippy -- -D warnings`
   - `cargo fmt --check`
   - `python tools/docs/collect_docs.py --report-missing`
5. Request review via `mcp_github_pull_request_review_write` or GitHub UI
6. Squash-merge to main — keep main history clean

## Roadmap ↔ GitHub Milestones


| Roadmap phase | Milestone name | Purpose |
|---|---|---|
| Phase 1–3 | `v0.1–v0.3` (historical) | Foundation and core API |
| Phase 4 | `v0.4` | Current active phase |
| Phase 5+ | `v0.5+` | Future phases |

Map roadmap acceptance gates to GitHub issue completion to track phase progress automatically.

## Using mcp_github_* Tools

Key tool patterns for Lurek2D work:

```
# Search for existing issues before creating
mcp_github_search_issues: query="lurek2d shadow physics", owner="...", repo="lurek2d"

# Create an issue with labels
mcp_github_issue_write: title, body, labels=["type:feature","module:graphics"], milestone=4

# Read a PR or issue
mcp_github_pull_request_read: owner, repo, pull_number
mcp_github_issue_read: owner, repo, issue_number

# List open issues for a milestone
mcp_github_list_issues: state="open", milestone=4, labels="status:ready"

# Add a comment
mcp_github_add_issue_comment: owner, repo, issue_number, body

# Merge a PR (only after quality gates pass)
mcp_github_merge_pull_request: owner, repo, pull_number, merge_method="squash"
```

Always search before creating — avoid duplicate issues.

## Git Commit Convention

```
type(scope): description
```

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
- One logical change per commit
- Never `git add .` — stage only files changed by the current task
- Confirm branch before committing: `git rev-parse --abbrev-ref HEAD`

## Release Process

1. Bump version in `Cargo.toml`
2. Update `CHANGELOG.md` with phase summary
3. Run full quality gate: `cargo test && cargo clippy -- -D warnings && cargo fmt --check`
4. Tag: `git tag v0.X.Y && git push origin v0.X.Y`
6. Re-run `mcp_github_get_latest_release` to verify the release was created correctly

## Anti-Patterns

- **Committing to main directly**: Always use a branch + PR
- **Giant PRs**: Split large roadmap phases into per-module PRs
- **Stale branches**: Delete branches after merge (`git push origin --delete feat/...`)
- **Missing labels**: Unlabeled issues are hard to filter — always apply at least `type:` and `module:`
