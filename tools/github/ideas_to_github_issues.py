#!/usr/bin/env python3
"""Create GitHub issues from each markdown file in docs/ideas/.

Usage:
  python tools/ideas_to_github_issues.py [--repo owner/repo] [--token TOKEN] [--path docs/ideas] [--label idea] [--dry-run] [--skip-existing]

Environment:
  GITHUB_TOKEN     (preferred) or pass --token

Behavior:
  - Each markdown file becomes one issue.
  - Title is derived from first heading (# ...) or filename.
  - Body is the full file content.
  - Label defaults to `idea`.
  - With --dry-run, no API call is made; plans are printed.
  - With --skip-existing, already-open issue with same title is skipped.

Notes:
  - Requires Python 3.7+.
  - No third-party dependencies are required.
"""

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request


def parse_args():
    p = argparse.ArgumentParser(description="Create GitHub issues from docs/ideas markdown files")
    p.add_argument("--repo", default=None, help="GitHub repo in owner/repo form")
    p.add_argument("--token", default=None, help="GitHub personal access token")
    p.add_argument("--path", default="docs/ideas", help="Path to ideas markdown files")
    p.add_argument("--label", default="idea", help="Label to apply to created issues")
    p.add_argument("--dry-run", action="store_true", help="Don't call GitHub, only print what would be done")
    p.add_argument("--skip-existing", action="store_true", help="Skip issues when one with same title already exists")
    return p.parse_args()


def get_token(explicit_token):
    if explicit_token:
        return explicit_token
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        raise RuntimeError("GitHub token not set. Use --token or set GITHUB_TOKEN environment variable.")
    return token


def get_repo(explicit_repo):
    if explicit_repo:
        if "/" not in explicit_repo:
            raise RuntimeError("--repo must be in owner/repo format")
        return explicit_repo

    # Try to read from git remote origin
    try:
        import subprocess
        out = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
    except Exception as e:
        raise RuntimeError("Failed to get GitHub repo from git remote; use --repo") from e

    # support SSH and HTTPS remotes
    if out.startswith("git@github.com:"):
        out = out[len("git@github.com:"):]
    elif out.startswith("https://github.com/"):
        out = out[len("https://github.com/"):]
    out = out.rstrip(".git")
    if "/" not in out:
        raise RuntimeError(f"Unexpected remote origin URL format: {out}")
    return out


def find_idea_files(path):
    if not os.path.isdir(path):
        raise RuntimeError(f"Path not found: {path}")
    files = [f for f in sorted(os.listdir(path)) if f.lower().endswith(".md")]
    return [os.path.join(path, f) for f in files]


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def extract_title(path, content):
    # Prefer first top-level heading. Fall back to filename base.
    for line in content.splitlines():
        m = re.match(r"^#\s+(.+)$", line.strip())
        if m:
            return m.group(1).strip()
    return os.path.splitext(os.path.basename(path))[0]


def call_github_api(url, token, data=None, method="GET"):
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "lurek2d-ideas-to-issues-script"
    }
    if data is not None:
        body = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
    else:
        body = None

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode("utf-8")
            return json.loads(content)
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(content)
        except Exception:
            payload = {"message": content}
        raise RuntimeError(f"GitHub API error {e.code}: {payload}")


def issue_exists(repo, title, token):
    query = urllib.parse.quote(f"repo:{repo} type:issue in:title \"{title}\"")
    url = f"https://api.github.com/search/issues?q={query}"
    data = call_github_api(url, token)
    return any(item.get("title", "") == title for item in data.get("items", []))


def create_github_issue(repo, title, body, label, token):
    url = f"https://api.github.com/repos/{repo}/issues"
    payload = {
        "title": title,
        "body": body,
        "labels": [label],
    }
    return call_github_api(url, token, data=payload, method="POST")


def main():
    args = parse_args()
    repo = get_repo(args.repo)

    if args.dry_run and not args.skip_existing:
        token = None
    else:
        token = get_token(args.token)

    idea_files = find_idea_files(args.path)
    if not idea_files:
        print(f"No markdown files found in {args.path}")
        return

    for path in idea_files:
        content = read_file(path)
        title = extract_title(path, content)
        print(f"\n=== {os.path.basename(path)} -> {title}")

        if args.skip_existing:
            exists = issue_exists(repo, title, token)
            if exists:
                print("  Skipping existing issue for title", title)
                continue

        if args.dry_run:
            print("  Dry run: would create issue:")
            print("   repository:", repo)
            print("   title:", title)
            print("   label:", args.label)
            continue

        created = create_github_issue(repo, title, content, args.label, token)
        issue_url = created.get("html_url")
        print("  Created", issue_url)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("Error:", e, file=sys.stderr)
        sys.exit(1)
