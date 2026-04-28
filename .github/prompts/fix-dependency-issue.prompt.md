---
description: "Fix a Cargo dependency issue."
---

# Fix Dependency Issue

## Goal
- Resolve Cargo.toml dependency problems.

## Inputs
- **Issue**: Version conflict, missing features, build failure
- **Affected crate**: Which dependency has the problem

## Steps
- Load documentation before changing any files.
- Read Cargo.toml for current dependency configuration
- Check the crate's documentation for correct version and features
- Fix version pin, feature flags, or remove unnecessary dependency
- Run cargo build and cargo test

## Success Criteria
- [ ] Cargo.toml uses semver pins (e.g., "0.27" not "*")
- [ ] mlua uses features = ["lua54", "vendored"]
- [ ] No unnecessary dependencies
- [ ] cargo build and cargo test pass

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-dependency-issue

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation
