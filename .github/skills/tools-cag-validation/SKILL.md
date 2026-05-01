---
name: tools-cag-validation
description: "Load this skill when validating, debugging, or maintaining CAG files and cag_validate.py rules. Skip it for engine code or game scripts."
---
# tools-cag-validation

## Mission
- Own cag_validate.py usage, rule meaning, and CAG validation standards.

## When To Load
- Run cag_validate.py.
- Debug agent, skill, prompt, or system-prompt validation errors.
- Review CAG file quality.

## When To Skip
- Engine code quality.
- General CAG authoring only.
- CI/CD workflow setup.

## Domain Knowledge
- `python tools/validate/cag_validate.py` is the entry gate for any CAG commit. It validates: (1) frontmatter keys and required values, (2) required sections (Mission, When To Load, When To Skip, Domain Knowledge), (3) line count cap per file, (4) known agent and skill names in cross-references, (5) description field phrasing (must start with "Load this" or "Skip it for"), (6) prompt `expected_agent` names against the live roster. A clean validator run is a commit prerequisite.
- Scoped runs for fast iteration: `--type skill` validates all skills; `--type agent` validates all agents; passing a single file path validates just that file. Use scoped runs during authoring. Run the full validator before committing.
- `python tools/audit/cag_link_check.py --strict` verifies that every `.md` file path referenced in any CAG file actually exists. Run after any file rename, move, or deletion in `.github/` or `docs/`. Dead links in CAG files silently degrade routing quality.
- `python tools/audit/cag_coverage.py` reports which agent roles lack associated skill bundles and which skills have no agent owner. An unowned skill is a candidate for removal; a role without primary skills is a routing gap.
- `python tools/audit/cag_persona_matrix.py` outputs the persona coverage matrix. Run it after any agent addition or removal to confirm no persona lost all its serving agents.
- Distinguishing content vs. validator defects: when validation fails, first confirm the rule exists in `cag_validate.py` source code. If the rule is correct and the file is wrong, fix the file. If the rule is outdated (removed agent name, old field), update the rule — but treat rule changes as a separate commit with a changelog entry.
- `--baseline` flag produces a baseline snapshot for comparison. Use it when starting a large CAG sweep: baseline at start, validate again at end, diff to confirm only intended changes.
- Common validator failures and their fixes: `unknown_agent_name` → agent file was deleted or renamed without updating references; `description_phrasing` → description does not start with "Load this skill when"; `section_missing` → one of the four required sections is absent or has the wrong heading.
- SKILL.md files must not contain code blocks (triple-backtick) or inline code (single-backtick). The validator enforces this. If domain knowledge requires an exact command, write it in plain prose without backtick formatting.
- After the validator passes, update `docs/CHANGELOG.md` with a `docs` or `chore` entry describing the CAG change. CAG changes without a changelog entry fail the commit hygiene check.
## Companion File Index
- None.

## References
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
- tools/audit/cag_coverage.py
- tools/audit/cag_persona_matrix.py
- tools/README.md
