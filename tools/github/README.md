# tools/github — GitHub Integration

Scripts for automating GitHub project management: generating issues from
idea files.

## Scripts

| Script | Purpose |
|---|---|
| `ideas_to_github_issues.py` | Create GitHub issues from each Markdown file in `ideas/` |

## Common usage

```powershell
# Create GitHub issues from ideas (requires GITHUB_TOKEN env var)
python tools/github/ideas_to_github_issues.py
```

## Requirements

Set the `GITHUB_TOKEN` environment variable to a Personal Access Token with
the `repo` scope before running `ideas_to_github_issues.py`.
