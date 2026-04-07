# tools/github — GitHub Integration

Scripts for automating GitHub project management: generating issues from
idea files and printing issue-to-idea mappings.

## Scripts

| Script | Purpose |
|---|---|
| `ideas_to_github_issues.py` | Create GitHub issues from each Markdown file in `docs/ideas/` |
| `print_issue_mapping.py` | Print a table mapping idea files to their GitHub issue numbers |

## Common usage

```powershell
# Create GitHub issues from ideas (requires GITHUB_TOKEN env var)
python tools/github/ideas_to_github_issues.py

# Print the current idea → issue mapping
python tools/github/print_issue_mapping.py
```

## Requirements

Set the `GITHUB_TOKEN` environment variable to a Personal Access Token with
the `repo` scope before running `ideas_to_github_issues.py`.
