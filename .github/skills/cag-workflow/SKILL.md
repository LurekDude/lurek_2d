---
name: cag-workflow
description: "Load this skill when editing .github agents, skills, prompts, or the system prompt, or when choosing the right CAG file type. Skip it for engine code, Lua scripts, or roadmap work."
---
# cag-workflow

## Mission
- Own .github file types, format rules, validation flow, and agent routing.

## When To Load
- Add or edit an agent, skill, prompt, or the system prompt.
- Decide if content belongs in a module spec, skill, agent, or prompt.
- Run cag_validate.py.
- Check agent routing.

## When To Skip
- Engine code work.
- Lua game scripting.
- Roadmap planning.

## Domain Knowledge
- File type selection rule: system prompt (`copilot-instructions.md`) = always-on global rules; agent (`*.agent.md`) = role identity, owned scope, and routing; skill (`SKILL.md`) = HOW-TO domain knowledge loaded on demand; prompt (`*.prompt.md`) = a focused multi-step workflow for one recurring task. Mixing these purposes into the wrong file type breaks discoverability.
- `description` field is the discovery key for skills and agents. It is searched first by the skill loader. The first sentence must state the trigger condition precisely. Bad: "General Rust coding help." Good: "Load this skill when writing or reviewing Rust engine code in src/."
- `When To Load` and `When To Skip` sections are hard routing guards. When To Skip prevents skill stacking: two overlapping skills loaded simultaneously create conflicting advice. If two skills have overlapping When To Load triggers, one of them is too broad.
- Shared policy belongs in `copilot-instructions.md` exactly once. If the same rule appears in a skill AND an agent AND a prompt, delete it from two of the three and add a link. Duplication causes version drift — rule changes get applied inconsistently.
- Companion File Index lists only files that the skill reader must open to execute the skill correctly. Do not list architecture reference docs that are nice-to-know. A companion file is a hard dependency for a specific action in the skill.
- Agent scope must be mutually exclusive. When two agents could plausibly handle the same request, that is a routing defect — the scope must be sharpened or one agent must defer explicitly. Check `docs/architecture/cag-system.md § 4.1` to confirm skill bundles do not create ambiguous routing.
- Before creating a new skill, check if an existing skill can absorb the domain knowledge. A new skill is justified when: (1) its When To Load triggers are unique and non-overlapping, (2) its domain knowledge is not duplicated elsewhere, (3) at least one agent lists it in their bundle.
- Token cost rule: every line added to `copilot-instructions.md` is loaded on every request. Anything that is not always-relevant belongs in a skill or agent, not in the system prompt. Prune regularly.
- Validation is mandatory before any CAG commit. Run `python tools/validate/cag_validate.py` for schema compliance, `python tools/audit/cag_link_check.py --strict` for file reference integrity. Both must pass.
- Workflow: baseline validate → minimal change → validate again → run `cag_link_check.py --strict` → update `docs/CHANGELOG.md` → commit. Never commit a CAG change without a green validator run.
## Companion File Index
- None.

## References
- .github/copilot-instructions.md
- .github/agents/README.md
- docs/architecture/cag-system.md
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
