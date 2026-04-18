- Never `git add .` — stage only files changed by the current task
- Confirm branch before committing: `git rev-parse --abbrev-ref HEAD`

### Release Process
1. Bump version in `Cargo.toml`
2. Update `CHANGELOG.md` with phase summary
3. Run full quality gate: `cargo test && cargo clippy -- -D warnings && cargo fmt --check`
4. Tag: `git tag v0.X.Y && git push origin v0.X.Y`
6. Re-run `mcp_github_get_latest_release` to verify the release was created correctly

### Anti-Patterns
- **Committing to main directly**: Always use a branch + PR
- **Giant PRs**: Split large roadmap phases into per-module PRs
- **Stale branches**: Delete branches after merge (`git push origin --delete feat/...`)
- **Missing labels**: Unlabeled issues are hard to filter — always apply at least `type:` and `module:`
