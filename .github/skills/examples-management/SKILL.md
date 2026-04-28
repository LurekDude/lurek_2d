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
- Keep examples self-contained and easy to run.
- Use examples to show one clear concept or workflow.
- Prefer realistic API use over placeholder calls.
- Keep demo structure and example structure distinct.
- Check coverage gaps with existing example audit tools when needed.
- Update supporting README text when the example changes materially.

## Companion File Index
- None.

## References
- content/examples/
- content/games/
- tools/audit/example_coverage.py