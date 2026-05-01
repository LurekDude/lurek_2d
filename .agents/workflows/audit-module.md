---
description: "Audit one module for cross-artifact sync issues, missing specs, or coverage gaps."
---

# Audit Module

## Goal
- Find and list sync gaps, missing specs, or coverage gaps for one engine module.

## Inputs
- Module name.
- Audit focus (spec sync, test coverage, API doc coverage, or all).

## Steps
1. Load quality-pipeline, documentation, and testing-rust before acting.
2. Run python tools/audit/doc_coverage.py for the module to find missing spec or API coverage.
3. Run python tools/audit/test_coverage.py for the module to find uncovered lurek.* behavior.
4. Compare src/<module>/ against docs/specs/<module>.md for drift.
5. Return a ranked list of gaps: missing spec sections, uncovered API surface, and missing tests.

## Success Criteria
- [ ] All audit gaps are listed with file references.
- [ ] Coverage tools ran without errors.
- [ ] Priority order is clear.

## Example Invocation
- /audit-module module=physics focus=all
