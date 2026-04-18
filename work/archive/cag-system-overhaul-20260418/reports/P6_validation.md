# P6 — System Prompt Slim-Down · Validation Report

**Date:** 2026-04-18
**Phase:** P6 (CAG System Overhaul)
**Agent:** CAG-Architect
**Branch:** refactor/src-migration-v2

## Before

| Metric                        | Value     |
|-------------------------------|-----------|
| `.github/copilot-instructions.md` lines | 298       |
| `.github/copilot-instructions.md` bytes | 26,344    |
| E001 (missing required section)         | 5         |
| E002 (>120 lines)                       | 1         |
| E003 (>8192 bytes)                      | 1         |
| E004 (forbidden inline roster)          | 0         |
| W005 (broken refs in system prompt)     | 12        |
| Baseline strict-mode total errors       | 7 (all in system prompt) |

## After

| Metric                        | Value     |
|-------------------------------|-----------|
| `.github/copilot-instructions.md` lines | 75        |
| `.github/copilot-instructions.md` bytes | 6,302     |
| E001                                    | 0         |
| E002                                    | 0         |
| E003                                    | 0         |
| E004                                    | 0         |
| W005 (broken refs in system prompt)     | 0         |
| `cag_validate.py --baseline` regressions | 0         |
| `cag_validate.py --baseline` total errors | 0 errors / 0 warnings |
| `cag_link_check.py --strict` broken refs in system prompt | 0 |

## Commands Run

```
python tools/validate/cag_validate.py --file .github/copilot-instructions.md
python tools/validate/cag_validate.py --baseline
python tools/audit/cag_link_check.py --strict
```

## Artifacts

- `.github/copilot-instructions.md` — rewritten to template (7 required sections in order, no inline rosters).
- `docs/architecture/cag-system.md` — placeholder created (full content in P9).

## Notes

- All 12 W005 broken refs from the previous file were eliminated by replacing `content/demos/` with `content/games/` and removing references to non-existent `tests/rust/{stress,config,security,game}/` and `tests/lua/content/library/` paths. The new prompt only references directories that exist on disk today.
- Baseline validator now reports 0 errors / 0 warnings across the entire CAG layer (system_prompt=1, agents=20, skills=33, prompts=56). P10 strict gate target effectively achieved early; remaining repo-wide broken links flagged by `cag_link_check.py --strict` (202 across 145 files) are outside the `.github/` scope and out of P6.
- No blockers for P10. P9 must replace the `docs/architecture/cag-system.md` placeholder with the full architecture doc before final sign-off.
