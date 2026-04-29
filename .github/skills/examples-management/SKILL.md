---
name: examples-management
description: "Load this skill when adding or reviewing content/examples/ or content/games/ files, README files, or conf.lua examples. Skip it for engine Rust, tests, docs/, or CAG work."
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
- content/examples/<module>.lua is the one-concept learning surface for public APIs.
- Examples should exercise real lurek.* usage and help close coverage gaps reported by example_coverage.py or coverage gap reports.
- Keep example setup tiny and README/conf notes short; this is not the place for long tutorial prose.
- Examples and showcase games serve different jobs: one concept versus a broader playable slice.
- Prefer stable APIs already reflected in docs/specs and generated docs.
- When an example changes materially, sync the supporting README text in the same pass.
- content/examples/ should help a user understand a module quickly, and tools like example_coverage.py or coverage gap reports are the right way to find under-served APIs.
- Stub-oriented example cleanup should keep story flow and real arguments, not just chase line-by-line coverage.
- The skill owns compact learning artifacts, not full demos, libraries, or tutorial docs.
## Companion File Index
- None.

## References
- content/examples/
- content/games/
- tools/audit/example_coverage.py
- logs/reports/coverage_gaps.md
