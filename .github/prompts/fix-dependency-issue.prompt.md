---
description: "Fix a dependency issue in Cargo.toml: version conflict, missing feature, or unnecessary dependency."
---

# Fix Dependency Issue

## Purpose

Resolve Cargo.toml dependency problems.

## Inputs

- **Issue**: Version conflict, missing features, build failure
- **Affected crate**: Which dependency has the problem

## Steps

1. Read `Cargo.toml` for current dependency configuration
2. Check the crate's documentation for correct version and features
3. Fix version pin, feature flags, or remove unnecessary dependency
4. Run `cargo build` and `cargo test`

## Acceptance

- [ ] `Cargo.toml` uses semver pins (e.g., `"0.27"` not `"*"`)
- [ ] mlua uses `features = ["lua54", "vendored"]`
- [ ] No unnecessary dependencies
- [ ] `cargo build` and `cargo test` pass

## References

- System prompt Dependencies table
- `Cargo.toml`
