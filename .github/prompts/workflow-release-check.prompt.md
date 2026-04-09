---
description: "Full release readiness check for Lurek2D. Use before tagging a release or merging to main. Runs all quality gates and produces a go/no-go verdict."
---

# Workflow: Release Check

**Purpose**: Run all quality gates and produce a binary go/no-go verdict for a Lurek2D release.
**Use When**: Before tagging a version, cutting a release binary, or merging a feature branch to `main`.
**Do Not Use When**: During active development — use individual gate prompts instead.
**Scope**: Full repository.

## Inputs

- `VERSION` — intended release tag (e.g., `v0.2.0`)
- `PLATFORM` — target platform(s) for the release binary (e.g., `windows-x86_64`, `linux-x86_64`)

## Steps

### Gate 1: Compilation
```powershell
cargo build --release
```
- Must complete with 0 errors

### Gate 2: Lint
```powershell
cargo clippy -- -D warnings
```
- Must complete with 0 warnings (treated as errors via `-D warnings`)

### Gate 3: Format
```powershell
cargo fmt --check
```
- Must pass (no unformatted files)

### Gate 4: Tests
```powershell
cargo test
```
- All tests must pass; 0 failures, 0 panics

### Gate 5: CAG Validation
```powershell
python tools/validate/cag_validate.py
```
- Must produce grade B or better on all file families
- 0 CRITICAL issues, ≤ 3 HIGH issues

### Gate 6: Example Smoke Test
```powershell
cargo run -- content/demos/hello_world
```
- Window must open and display without panic
- Close manually; verify no stderr errors

### Gate 7: Documentation Check
- `docs/API/lua_api_reference_generated.md` — every `lurek.*` function in the code has an entry
- `README.md` — version badge and feature list current

### Gate 8: Security Audit
```powershell
cargo audit
```
- 0 known vulnerabilities in dependencies

## Outputs

- Console output from each gate
- Go/no-go verdict with specific blocking issues listed

## Acceptance

- [ ] Gate 1 (build): PASS
- [ ] Gate 2 (clippy): PASS
- [ ] Gate 3 (fmt): PASS
- [ ] Gate 4 (tests): PASS
- [ ] Gate 5 (CAG): PASS
- [ ] Gate 6 (smoke): PASS
- [ ] Gate 7 (docs): PASS
- [ ] Gate 8 (audit): PASS
- [ ] All gates passing → tag `<VERSION>` and publish binary

## References

**Required Skills**: `rust-coding`, `testing-rust`, `tools-cag-validation`
**Suggested Agents**: `Reviewer`, `Tester`
**Related Prompts**: `run-quality-gates.prompt.md`, `review-code-quality.prompt.md`
**Commands**:
```powershell
cargo build --release
cargo clippy -- -D warnings
cargo fmt --check
cargo test
python tools/validate/cag_validate.py
cargo audit
```
