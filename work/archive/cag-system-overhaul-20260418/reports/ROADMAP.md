# CAG System Overhaul — Roadmap

**Session**: `cag-system-overhaul-20260418`
**Branch**: `refactor/src-migration-v2` (per `work/branch.txt`)
**Author**: Planner
**Date**: 2026-04-18

---

## 1. Executive Summary

Lurek2D's CAG layer has grown organically to 20 agents, 32 skills, 45 prompts, and a 297-line / 25 KB system prompt that inlines every roster — far past the point where Claude Sonnet can reliably navigate it without burning context on directory enumeration. This overhaul standardises every CAG file type behind a mechanically-checkable schema, slims the system prompt to a discovery index, extracts all code from `SKILL.md` files into companion folders, rewrites all 45 prompts to a Claude-Code-aligned template, and codifies AI-first / GitOps / no-UI-editor philosophy in a new `docs/architecture/cag-system.md`. Success is measured by `cag_validate.py` returning zero errors across `.github/`, every agent justifying its existence against six personas, and the system prompt dropping below 120 lines while remaining sufficient for cold-start agent navigation.

**Biggest risk**: refactoring all 98 CAG files in parallel will silently break inter-file links and `applyTo` patterns that downstream prompts depend on. **Mitigation**: P0 audit produces an authoritative link graph; P2 ships a link-checker before any rewrite phase begins; every refactor phase ends with `cag_validate.py` green as a gate.

---

## 2. Personas & Value Map

Six personas the engine and CAG layer must serve:

- **EngDev** — Engine developer (Rust core)
- **GameDev** — Game developer using `lurek.*` Lua API
- **Modder** — Game modder (Lua scripts loaded via `lurek.mods`)
- **Player** — End-user playing demos / shipped games
- **GameTest** — Game tester (functional QA on Lua games)
- **EngTest** — Engine tester (Rust + Lua test suites, fuzz, perf)

| Agent | EngDev | GameDev | Modder | Player | GameTest | EngTest | Verdict |
|---|---|---|---|---|---|---|---|
| Manager | yes | yes | yes | indirect | yes | yes | keep |
| Planner | yes | yes | indirect | no | yes | yes | keep |
| Research | yes | yes | yes | no | yes | yes | keep |
| Solver | yes | yes | indirect | no | yes | yes | keep |
| Architect | yes | indirect | no | no | indirect | yes | keep |
| Developer | yes | indirect | no | no | indirect | yes | keep |
| Lua-Designer | yes | yes | yes | no | indirect | indirect | keep |
| Renderer | yes | indirect | no | indirect | no | indirect | keep |
| Physicist | yes | indirect | no | no | no | indirect | keep |
| Audio-Eng | yes | indirect | no | no | no | indirect | keep |
| Tester | yes | yes | yes | no | yes | yes | keep |
| Reviewer | yes | yes | indirect | no | yes | yes | keep |
| Debugger | yes | yes | indirect | no | yes | yes | keep |
| Optimizer | yes | yes | no | indirect | indirect | yes | keep |
| Doc-Writer | yes | yes | yes | indirect | yes | yes | keep |
| Security | yes | indirect | yes | indirect | indirect | yes | keep |
| CAG-Architect | yes | indirect | indirect | no | indirect | indirect | keep (meta) |
| Configurator | yes | yes | yes | indirect | yes | yes | keep |
| Hacker | yes | indirect | indirect | no | indirect | yes | **review for merge → Security** |
| Player (persona-reviewer) | indirect | yes | indirect | yes | yes | no | **review for merge → Reviewer (UX lens)** |

**P4 decisions (pre-approved by user 2026-04-18)**:
- `Hacker` — **KEEP**. Document scope boundary vs Security explicitly in `hacker.agent.md` Anti-patterns section.
- `Player` (persona-reviewer agent) — **KEEP**. Document scope boundary vs Reviewer's UX lens explicitly in `player.agent.md`.
- `Configurator` and `Lua-Designer` — verify boundary on `conf.lua`/`conf.toml`, no merge expected.
- `Renderer`, `Physicist`, `Audio-Eng` — keep as distinct domain specialists (distinct skill loads).

---

## 3. Phases

Phase ID convention: `P{n}-{slug}`. Every phase ends with a JSONL log entry, a git commit (`type(scope): description`), and a `docs/CHANGELOG.md` entry under the current version (PATCH bump per phase, MINOR at P11 close).

### P0 — Audit (no edits)

- **Goal**: Produce authoritative inventory + gap report of the entire `.github/` CAG layer.
- **Owner**: CAG-Architect
- **Inputs**: `.github/**/*`, current `tools/validate/cag_validate.py` output, `tools/README.md`.
- **Deliverables**:
  - `work/cag-system-overhaul-20260418/reports/P0_inventory.md` — file counts, line counts, link graph, fenced-code-block count per SKILL.md.
  - `work/cag-system-overhaul-20260418/data/cag_link_graph.json` — every cross-reference between agents/skills/prompts/instructions.
  - `work/cag-system-overhaul-20260418/reports/P0_gaps.md` — missing prompts, orphan skills, agents with no inbound references.
- **Done-when**: All 4 files exist; `P0_inventory.md` accounts for 20 agents, 32 skills, 45 prompts, 1 system prompt (counts taken from current state, must be reverified).
- **Dependencies**: none.
- **Parallelizable with**: none (gates everything).
- **Artifacts touched**: 0 edits, ~98 reads.

### P1 — Standards Definition

- **Goal**: Author the new templates and validation rules for every CAG file type.
- **Owner**: CAG-Architect (with Doc-Writer review)
- **Inputs**: P0 outputs.
- **Deliverables**:
  - `work/.../reports/standards/SYSTEM_PROMPT_TEMPLATE.md`
  - `work/.../reports/standards/AGENT_TEMPLATE.md`
  - `work/.../reports/standards/SKILL_TEMPLATE.md` (with explicit "no fenced code blocks" rule and companion-file layout)
  - `work/.../reports/standards/PROMPT_TEMPLATE.md` (Claude-Code aligned: frontmatter, mission, inputs, tools, success criteria, anti-patterns)
  - `work/.../reports/standards/CAG_ARCHITECTURE_DOC_TEMPLATE.md` (skeleton for P9 deliverable)
- **Done-when**: 5 template files exist; each lists required sections, max line count, forbidden patterns, and validator rule IDs (`E001`, `W042`, …).
- **Dependencies**: P0.
- **Parallelizable with**: P2 (validator design can co-evolve with templates).
- **Artifacts touched**: 5 new files.

### P2 — Validator & Analytics Upgrade

- **Goal**: Extend `cag_validate.py` and add coverage/link/persona checkers that mechanically enforce P1 standards.
- **Owner**: Developer (with CAG-Architect spec review)
- **Inputs**: P1 standards.
- **Deliverables**:
  - `tools/validate/cag_validate.py` — extended with rules from P1 (fenced-code-block detector for skills, frontmatter schema per type, link target resolver, line-count caps).
  - `tools/audit/cag_coverage.py` — new: emits per-file coverage table (sections present, missing, extra).
  - `tools/audit/cag_link_check.py` — new: resolves every `[…](…)` and `c:\…` reference inside `.github/`; reports broken targets.
  - `tools/audit/cag_persona_matrix.py` — new: parses agent frontmatter `personas:` field and emits the matrix from §2 automatically.
  - `tools/validate/README.md` and `tools/audit/README.md` updated with new entries.
  - `work/.../reports/P2_baseline_report.md` — output of all 4 tools against the **current** (pre-refactor) `.github/` tree.
- **Done-when**: All 4 tools run with `--help` returning 0; baseline report committed; new rules documented in `tools/validate/README.md`.
- **Dependencies**: P1.
- **Parallelizable with**: P0 read-only follow-ups; cannot start before P1 schema is frozen.
- **Artifacts touched**: ~6 tool files.

### P3 — Skills Refactor

- **Goal**: Bring all 32 skills to the new SKILL.md template; extract every fenced code block to a companion file; deepen domain content.
- **Owner**: CAG-Architect (drives) + domain agents consulted per skill (Renderer reviews `gpu-programming`, Physicist reviews `module-architecture` boundary cases, etc.).
- **Inputs**: P1 SKILL_TEMPLATE.md, P2 baseline report.
- **Deliverables**:
  - `.github/skills/<name>/SKILL.md` rewritten for all 32 skills.
  - `.github/skills/<name>/examples/` and/or `templates/`, `snippets/` populated with extracted code; each referenced from SKILL.md by relative path.
  - `work/.../reports/P3_skills_diff.md` — per-skill before/after summary.
- **Done-when**:
  - `python tools/audit/cag_coverage.py --type skill` reports 100% section coverage.
  - `cag_validate.py` rule "no fenced code blocks in SKILL.md" returns 0 violations.
  - `cag_link_check.py` finds 0 broken links from skills to companion files.
- **Dependencies**: P1, P2.
- **Parallelizable with**: P4 (different file trees), P5 (different file trees). Do **not** parallelize with P6 (system prompt references skill names).
- **Artifacts touched**: 32 SKILL.md + ~60–120 new companion files.

### P4 — Agents Refactor

- **Goal**: Slim every agent to mission/inputs/outputs/routing/scope; resolve overlap flags from §2; persona-justify each.
- **Owner**: CAG-Architect (drives) + Architect (boundary decisions on flagged agents).
- **Inputs**: P1 AGENT_TEMPLATE.md, P0 gap report, §2 persona matrix.
- **Deliverables**:
  - `.github/agents/*.agent.md` rewritten (20 files).
  - `.github/agents/README.md` updated with new shared contract section.
  - `work/.../reports/P4_agent_decisions.md` — per agent: kept / merged / scope-changed, with rationale citing personas.
- **Done-when**:
  - `cag_validate.py --type agent` returns 0 errors.
  - `cag_persona_matrix.py` shows every agent serves ≥1 persona directly (no agent with all "no").
  - `Hacker` and `Player` agents kept (per user decision) — boundary documentation present in their `Anti-patterns` sections.
- **Dependencies**: P1, P2.
- **Parallelizable with**: P3, P5.
- **Artifacts touched**: 21 files.

### P5 — Prompts Refactor

- **Goal**: Rewrite all 45 prompts to the Claude-Code template; dedupe; fix all link references; identify gaps.
- **Owner**: CAG-Architect (drives) + Doc-Writer (link integrity).
- **Inputs**: P1 PROMPT_TEMPLATE.md, P0 gap report.
- **Deliverables**:
  - `.github/prompts/*.prompt.md` rewritten (45 files).
  - `work/.../reports/P5_prompts_dedupe.md` — duplicate clusters and resolution (merge / keep both / retire).
  - `work/.../reports/P5_prompts_gaps.md` — proposed new prompts (e.g. `create-tilemap-feature` already exists; check for `create-particle-effect`, `create-shader-effect`, etc.).
  - Any new prompt files added to fill gaps.
- **Done-when**:
  - `cag_validate.py --type prompt` returns 0 errors.
  - `cag_link_check.py` finds 0 broken targets in prompts.
  - Every prompt declares the skills it loads and the agent it expects to run under.
- **Dependencies**: P1, P2; should follow P3 so skill paths stabilise (relax to "may run in parallel with P3 if skill *names* are frozen in P1").
- **Parallelizable with**: P4. Soft-serial after P3.
- **Artifacts touched**: 45+ files.

### P6 — System Prompt Slim-Down

- **Goal**: Reduce `.github/copilot-instructions.md` to a high-level "bible" that points to discovery mechanisms instead of inlining every roster.
- **Owner**: CAG-Architect.
- **Inputs**: P1 SYSTEM_PROMPT_TEMPLATE.md, finalised agent/skill rosters from P3 + P4.
- **Deliverables**:
  - `.github/copilot-instructions.md` rewritten — target ≤ 120 lines, ≤ 8 KB. Must explain *how* to discover skills/agents (load `docs/architecture/cag-system.md`; consult `.github/skills/` directory; read agent frontmatter), not list them.
  - All inline skill / agent / prompt enumerations removed; replaced by single-line directives ("All skills live in `.github/skills/<name>/SKILL.md` — load on demand based on task domain").
  - Binding constraints (A-01..A-04, B-01..B-05) stay; cross-artifact sync table stays; everything else migrates out.
- **Done-when**:
  - File ≤ 120 lines (current: 297) and ≤ 8 KB (current: 25 KB).
  - `cag_link_check.py` clean.
  - Cold-start test: a fresh agent given only the new system prompt + the user request "fix a bug in `src/physics/`" can identify the right skill (`dev-debugging` + `module-architecture`) and right agent (`Debugger` then `Developer`) without inline lists. Verified by Reviewer in P10.
- **Dependencies**: P3, P4 (skill/agent files must be stable).
- **Parallelizable with**: P9 (new architecture doc) — they reference each other but can co-author.
- **Artifacts touched**: 1 file.

### P7 — Tools Awareness Pass

- **Goal**: Every script in `tools/` has a module docstring + entry in its subfolder README; every agent that should invoke a tool documents the invocation in its routing section.
- **Owner**: Doc-Writer (drives) + Developer (verifies docstrings parse and tool runs).
- **Inputs**: `tools/**/*.py`, `tools/**/README.md`, refactored agents from P4.
- **Deliverables**:
  - Updated `tools/<sub>/README.md` for every subfolder (`audit`, `validate`, `fix`, `docs`, `dev`, `demos`, `dist`, `github`, `mods`, `ui`, `screenshots`, `assets`).
  - Module docstrings added/repaired to every `.py` under `tools/`.
  - `work/.../reports/P7_tools_index.md` — final flat index (script → purpose → invoking agent(s)).
  - Agent files (P4 output) augmented where they invoke specific tools.
- **Done-when**:
  - Every `*.py` under `tools/` has a top-of-file `"""docstring"""`.
  - Every subfolder README lists every script in that folder.
  - `tools/README.md` index is regenerated and matches reality.
- **Dependencies**: P4 (agents must exist in new form).
- **Parallelizable with**: P5, P6.
- **Artifacts touched**: ~12 README files, ~50–80 .py files (docstring-only edits).

### P8 — Workflow Enforcement

- **Goal**: Bake Manager → Planner → specialists → CAG-Architect routing into the agent definitions; require commit + CHANGELOG step at every phase end.
- **Owner**: CAG-Architect.
- **Inputs**: refactored agents (P4), system prompt (P6).
- **Deliverables**:
  - `Manager` agent updated to mandate Planner involvement when ≥3 agents or ≥5 files are in scope.
  - `CAG-Architect` agent updated with the "end-of-session sweep" mandate (asks: did this session imply a CAG update? if yes, route back).
  - All implementation-phase agents (Developer, Renderer, Physicist, Audio-Eng, Lua-Designer, Doc-Writer, Tester) include "commit + CHANGELOG" as a gating step in their workflow section.
  - `work/.../reports/P8_workflow_check.md` — sequence diagram (text) of a canonical multi-agent session.
- **Done-when**:
  - `cag_validate.py` rule "agent has explicit handoff target" passes for all agents.
  - Manager's workflow section explicitly names Planner, the work-folder layout, and the CAG-Architect end gate.
- **Dependencies**: P4.
- **Parallelizable with**: P7, P9.
- **Artifacts touched**: 5–8 agent files.

### P9 — Architecture Doc

- **Goal**: Author `docs/architecture/cag-system.md` — the user-facing reference for the entire CAG system.
- **Owner**: Doc-Writer (drives) + CAG-Architect (review).
- **Inputs**: P1 CAG_ARCHITECTURE_DOC_TEMPLATE.md, all refactored CAG files.
- **Deliverables**:
  - `docs/architecture/cag-system.md` — sections: Philosophy (AI-first / no-UI / GitOps), File Types (system prompt / agents / skills / prompts / instructions), Discovery Mechanism, Routing Rules, Persona Map, Validator & Tooling, Authoring a New Agent/Skill/Prompt, End-of-Session CAG Sweep.
  - System prompt (P6) links to it as the canonical reference.
  - `README.md` (repo root) — add one line under documentation pointing to the new doc.
- **Done-when**: file exists; `cag_link_check.py` confirms inbound link from system prompt and README; doc passes the Doc-Writer self-review checklist.
- **Dependencies**: P3, P4, P5, P6 (content sources stabilised); structure can begin after P1.
- **Parallelizable with**: P6, P7, P8.
- **Artifacts touched**: 1 new doc, 2 edited.

### P10 — Final Validation

- **Goal**: Full-tree green run + cold-start agent test + persona check.
- **Owner**: Reviewer (drives) + CAG-Architect (sign-off).
- **Inputs**: All prior phase outputs.
- **Deliverables**:
  - `work/.../reports/P10_final_report.md` — output of `cag_validate.py`, `cag_coverage.py`, `cag_link_check.py`, `cag_persona_matrix.py` against final tree.
  - Cold-start scenarios (≥3) executed and recorded: e.g. "fix physics bug", "add new lurek API function", "create a tilemap demo" — verify the new system prompt routes correctly.
  - CAG-Architect end-of-session sign-off entry in `logs/agent_log.jsonl`.
- **Done-when**:
  - All 4 tools exit 0 with 0 errors and 0 warnings on `.github/`.
  - All 3 cold-start scenarios route to correct agent + skill set without inline lists.
  - Sign-off recorded.
- **Dependencies**: P3–P9 all complete.
- **Parallelizable with**: none (gating).
- **Artifacts touched**: 1 report.

### P11 — Final Commit & CHANGELOG

- **Goal**: Per-phase commits already exist; tag a coherent MINOR bump and finalise CHANGELOG narrative.
- **Owner**: Developer (mechanical) + CAG-Architect (CHANGELOG wording).
- **Inputs**: All phase commits.
- **Deliverables**:
  - `Cargo.toml` MINOR bump (e.g. `0.5.0` → `0.6.0`) — CAG overhaul is a tooling/process MINOR feature.
  - `docs/CHANGELOG.md` — consolidated entry under new version listing each phase as a bullet under `### Changed`.
  - Optional git tag.
- **Done-when**: `cargo check` still passes (sanity), CHANGELOG entry committed, `python tools/validate/cag_validate.py` returns 0.
- **Dependencies**: P10.
- **Parallelizable with**: none.
- **Artifacts touched**: 2 files.

---

## 4. Standards Sketch (one paragraph each)

**System prompt** — Frontmatter (none — it's the root). Body sections, in order: (1) one-paragraph engine identity, (2) binding constraints A-01..B-05 verbatim, (3) cross-artifact sync table, (4) discovery directives ("agents live in `.github/agents/`, load on demand; skills live in `.github/skills/<name>/SKILL.md`, load when description matches"), (5) link to `docs/architecture/cag-system.md`. No agent roster. No skill catalog. No prompt list. Hard cap 120 lines / 8 KB. Lurek2D-specific facts only — no generic Rust advice.

**Agent file** — YAML frontmatter: `name`, `mission` (one sentence), `personas` (list from §2 vocabulary), `primary_skills`, `secondary_skills`, `routes_to` (list of agent names), `loads_tools` (list of `tools/...` scripts). Body: Mission · Scope (owns / must-not-become) · Inputs · Outputs · Workflow (numbered steps) · Routing Table · Anti-patterns. No code blocks larger than a single inline command. Hard cap 200 lines.

**Skill file** — YAML frontmatter: `name`, `description` (the `<description>` shown to the loader; must include trigger conditions and skip conditions), `companion_files` (list). Body: Mission · When to load · When to skip · Domain knowledge (deep, prose) · References to companion files (no inline code). Companion code lives under `.github/skills/<name>/examples/*.{rs,lua,toml}`, `.github/skills/<name>/templates/*`, `.github/skills/<name>/snippets/*`. Validator rule `E101` rejects any fenced ```` ``` ```` block in SKILL.md. Inline code allowed only via single backticks for symbol names.

**Prompt file (Claude-Code template)** — YAML frontmatter: `description`, `mode` (default agent or specific), `tools` (allow/deny list), `loads_skills` (list). Body: Goal · Inputs (what the user must provide) · Steps (numbered, each step references a tool and/or skill) · Success Criteria (binary) · Anti-patterns · Example Invocation. Reference syntax for skills: `[skill: name](.github/skills/name/SKILL.md)`. Reference syntax for tools: `[tool: name](tools/path/script.py)`. Validator enforces every referenced skill exists.

**`docs/architecture/cag-system.md`** — Audience: human contributors and AI agents alike. Sections: (1) Philosophy — AI-first, no GUI editor, GitOps; (2) File-Type Catalog with one-paragraph each; (3) Discovery Flow diagram (text-tree showing how an agent loads system prompt → applicable skills → routed agent); (4) Six-persona model with the full §2 matrix; (5) Validator & Tooling — when each tool runs, what each rule means; (6) Authoring guides (How to add an agent / skill / prompt — checklist + template path); (7) End-of-session CAG sweep contract. Linked from `.github/copilot-instructions.md` and root `README.md`.

---

## 5. Tool Inventory Decision

**Existing CAG-relevant tools** (audited from `tools/validate/` and `tools/audit/`):

| Tool | Status | Decision |
|---|---|---|
| `tools/validate/cag_validate.py` (12 KB) | active | **extend** — add rules from P1 (frontmatter schemas per type, fenced-code-block detector, link resolver, line caps). |
| `tools/audit/audit_module.py` | unrelated to CAG | leave alone. |
| `tools/audit/doc_coverage.py` | unrelated to CAG | leave alone. |
| (no link checker today) | missing | **add** `tools/audit/cag_link_check.py`. |
| (no coverage report today) | missing | **add** `tools/audit/cag_coverage.py`. |
| (no persona matrix today) | missing | **add** `tools/audit/cag_persona_matrix.py`. |

**To retire**: none — current `cag_validate.py` is keep-and-extend, no other CAG tooling exists yet.

**New tool budget**: 3 new Python scripts (~150–300 LOC each), all under `tools/audit/`.

---

## 6. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | **Scope creep** — refactor balloons into engine doc rewrite. | high | high | Roadmap phases are file-type-scoped; any out-of-scope finding becomes a new ticket, not a phase extension. CAG-Architect enforces. |
| 2 | **Broken prompts/agents during refactor** — link rot, missing skill refs. | high | high | P2 ships `cag_link_check.py` before any rewrite phase; every refactor phase gates on it returning 0. |
| 3 | **Validator false positives** — over-strict rule blocks legitimate content (e.g. inline `` `code` `` in SKILL.md misread as fenced block). | medium | medium | P2 baseline run against current tree first; every new rule must produce ≤ 5% false positives on the legacy corpus before activation. |
| 4 | **Persona-removal dispute** — `Hacker` / `Player` merger flagged but Architect disagrees. | medium | low | Decisions are explicit in `P4_agent_decisions.md`; "defer" is a valid outcome and does not block P5–P11. |
| 5 | **Cold-start regression** — slimmed system prompt loses critical info, agents start hallucinating APIs. | medium | high | P10 cold-start scenarios are mandatory gates; if any fails, P6 reverts to a longer prompt and the discovery mechanism is patched. Lua API grounding rule (every game/demo task consults `docs/API/lua-api.md`) is preserved verbatim from current prompt. |

---

## 7. Agent Routing Plan

| Phase | Lead Agent | Supporting Agents | Reviewer |
|---|---|---|---|
| P0 Audit | CAG-Architect | Research (read-only crawls) | — |
| P1 Standards | CAG-Architect | Doc-Writer | Architect |
| P2 Validator upgrade | Developer | CAG-Architect (spec) | Tester |
| P3 Skills refactor | CAG-Architect | Renderer/Physicist/Audio-Eng/Lua-Designer (per-skill domain review) | Reviewer |
| P4 Agents refactor | CAG-Architect | Architect (boundary calls on flagged agents) | Reviewer |
| P5 Prompts refactor | CAG-Architect | Doc-Writer | Reviewer |
| P6 System prompt slim-down | CAG-Architect | Architect | Reviewer |
| P7 Tools awareness | Doc-Writer | Developer (docstring verification) | Reviewer |
| P8 Workflow enforcement | CAG-Architect | Manager (self-edit), Planner (self-edit) | Architect |
| P9 Architecture doc | Doc-Writer | CAG-Architect | Reviewer |
| P10 Final validation | Reviewer | Tester (tool runs) | CAG-Architect (sign-off) |
| P11 Commit & CHANGELOG | Developer | CAG-Architect (wording) | — |

**Parallelism map** (concrete):

```
P0 → P1 → ┬─ P2 ───────────────┐
          ├─ P3 ────────────┐  │
          ├─ P4 ─┐          │  │
          └─ P5 ┤           │  │
                ↓           ↓  ↓
             ┌──┴──── P6 ──┴──┴──┐
             ├────── P7 ─────────┤
             ├────── P8 ─────────┤
             └────── P9 ─────────┘
                          ↓
                         P10 → P11
```

True parallel windows:
- After P2 finishes: **P3 ‖ P4 ‖ P5** (different file trees, shared validator).
- After P4 finishes: **P6 ‖ P7 ‖ P8 ‖ P9** (different concerns).

---

## 8. Acceptance Criteria (whole effort)

- [ ] `python tools/validate/cag_validate.py` exits 0 with 0 errors and 0 warnings on every file under `.github/`.
- [ ] `python tools/audit/cag_coverage.py` reports 100% required-section coverage for all agents, skills, prompts.
- [ ] `python tools/audit/cag_link_check.py` reports 0 broken cross-references inside `.github/` and from `.github/` into `docs/`, `tools/`, `src/`.
- [ ] `python tools/audit/cag_persona_matrix.py` shows every agent serves ≥ 1 persona directly.
- [ ] All 32 `SKILL.md` files contain zero fenced code blocks (`` ``` `` count = 0); every code example lives under `.github/skills/<name>/{examples,templates,snippets}/`.
- [ ] `.github/copilot-instructions.md` ≤ 120 lines and ≤ 8 KB (down from 297 / 25 KB).
- [ ] `docs/architecture/cag-system.md` exists, is linked from `.github/copilot-instructions.md` and from root `README.md`.
- [ ] `docs/CHANGELOG.md` has one entry per phase under the new MINOR version, plus a consolidating summary at the top of that version block.
- [ ] Every `tools/**/*.py` has a module docstring; every `tools/<sub>/README.md` is up to date.
- [ ] At least 3 cold-start scenarios pass in P10 without the agent requiring inline rosters from the system prompt.
- [x] `Hacker` and `Player` agents kept (user decision 2026-04-18); boundary documented in their agent files.
- [ ] Manager agent definition explicitly mandates Planner involvement and CAG-Architect end-of-session sweep.

---

**End of Roadmap.**
