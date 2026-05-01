---
description: "Load when adding or reviewing content/examples/ or content/games/ files, README files, or conf.lua examples. Skip for engine Rust, tests, docs/, or CAG work."
alwaysApply: false
---

# examples-management

## Mission
- Own example and demo content structure, clarity, and coverage value.

## When To Load
- Add or update content/examples/.
- Review content/games/ example content.
- Check example README or conf files.
- Improve API coverage through examples.

## When To Skip
- Engine Rust code.
- Tests.
- docs/ content.
- CAG files.

## Domain Knowledge
- content/examples/<module>.lua is the one-concept learning surface for public APIs; each example should answer one clear question for a game author quickly.
- Examples should exercise real lurek.* usage and help close coverage gaps reported by example_coverage.py.
- Keep example setup tiny and README or conf notes short.
- Examples and showcase games serve different jobs: an example teaches one concept fast, while a game or demo proves a broader playable slice.
- Prefer stable APIs already reflected in docs/specs and generated docs.
- When an example changes materially, sync the supporting README text in the same pass.
- Good examples in this repo are short enough to scan, real enough to copy, and stable enough that docs can point to them.

## References
- content/examples/
- content/games/
- tools/audit/example_coverage.py
- logs/reports/coverage_gaps.md
