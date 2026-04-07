#!/usr/bin/env python3
"""
print_issue_mapping.py — Parse and print idea-to-GitHub-issue number mapping.

Reads a cached GitHub issue list JSON and prints a table of idea file ->
issue number mappings. Companion to ideas_to_github_issues.py.

Usage:
    python tools/github/print_issue_mapping.py      # prints mapping table
"""
import json
from pathlib import Path
p=Path(r"c:\Users\tombl\AppData\Roaming\Code\User\workspaceStorage\80034e2b0fc73651bb5cf96b8b5cf858\GitHub.copilot-chat\chat-session-resources\83a61408-9640-4431-8a16-e8b983870b4f\call_AA6P0cR373CENXNbwUQ6pKeL__vscode-1775043684860\content.json")
if not p.exists():
    raise SystemExit("content.json not found")
obj=json.loads(p.read_text(encoding='utf-8'))
for item in obj.get('items',[]):
    print(f"{item['number']}|||{item['title']}")
