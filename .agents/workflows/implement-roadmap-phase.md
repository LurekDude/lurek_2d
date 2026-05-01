---
description: "Implement a roadmap phase from an accepted phase description with all required gates."
---

# Implement Roadmap Phase

## Goal
- Complete one accepted roadmap phase from start to validated close.

## Inputs
- Phase description or phase file path.
- Acceptance gate defined in the phase.
- Constraints and excluded domains.

## Steps
1. Load module-architecture, rust-coding, testing-rust, and documentation before acting.
2. Read the phase description, identify all required deliverables, and map them to owner slices.
3. Implement the smallest slice first and validate immediately before continuing.
4. Sync docs/specs/<module>.md, tests, examples, and docs/CHANGELOG.md as each slice completes.
5. Run the final acceptance gate defined in the phase. Return pass or fail evidence.

## Success Criteria
- [ ] All phase deliverables are completed.
- [ ] All required sync artifacts are current.
- [ ] The acceptance gate is green.
- [ ] docs/CHANGELOG.md is updated.

## Example Invocation
- /implement-roadmap-phase phase=docs/phases/phase-tilemap.md
