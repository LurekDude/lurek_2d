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
- content/examples/<module>.lua is the one-concept learning surface for public APIs, so each example should answer one clear question for a game author quickly.
- Examples should exercise real lurek.* usage and help close coverage gaps reported by example_coverage.py or coverage reports, but they should still feel like believable usage instead of synthetic parameter stuffing.
- Keep example setup tiny and README or conf notes short; this is not the place for long tutorial prose, branching content, or heavy asset management.
- Examples and showcase games serve different jobs: an example teaches one concept fast, while a game or demo proves a broader playable slice.
- Prefer stable APIs already reflected in docs/specs and generated docs so examples remain trustworthy onboarding material.
- When an example changes materially, sync the supporting README text in the same pass so the entry point and the explanation continue to match.
- content/examples/ should help a user understand a module quickly, and coverage-gap tooling is the right way to find under-served APIs without inventing arbitrary examples.
- Stub-oriented cleanup should keep story flow, realistic arguments, and meaningful names rather than chasing line-by-line coverage with unnatural snippets.
- Keep assets and setup local to the concept being shown; if the content starts needing broader game state, it probably wants to become a demo instead.
- Good examples in this repo are short enough to scan, real enough to copy, and stable enough that docs can point to them as living evidence.
- This skill owns compact learning artifacts and example coverage value, not full demos, reusable libraries, or tutorial-style documentation.
## Companion File Index
- None.

## References
- content/examples/
- content/games/
- tools/audit/example_coverage.py
- logs/reports/coverage_gaps.md
