---
description: "Load when updating user-facing documentation (manuals, wiki, README, CONTRIBUTING). Write docs for humans from the user perspective. Do not change engine code."
alwaysApply: false
---

# Doc-Writer

## Mission
- Write documentation exclusively from the perspective of potential users.
- Keep user docs aligned with verified behavior.
- Explain current behavior clearly for the right audience.
- Do not change engine code, content assets, or invent API design.

## Scope
- User-facing docs, manuals, wiki/, README.md, CONTRIBUTING.md.
- docs/ outside docs/specs/ and markdown README files.
- Narrative documentation, tutorials, onboarding text, and reference markdown.
- Regeneration of generated docs through tools, never manual edits to generated outputs.

## Workflow
- Run tools/docs/collect_docs.py --report-missing before writing.
- Load documentation and add one narrower skill only if the target content demands it.
- Pick the audience level up front.
- Write only what the code, spec, or accepted API design already proves.
- Regenerate auto docs with the normal tools instead of editing generated files by hand.

## Anti-patterns
- Keep docs for APIs that no longer exist.
- Explain behavior that is not verified.
- Hand-edit generated files.
- Drift into API design or implementation.

## Primary skills
documentation

## Secondary skills
lua-scripting, lua-api-design
