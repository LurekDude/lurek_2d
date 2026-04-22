# CAG System (Lurek2D)

**Audience:** human contributors **and** AI agents.
**Source of truth:** this document. The system prompt at [.github/copilot-instructions.md](../../.github/copilot-instructions.md) is a discovery index that points here.

The **CAG layer** (Context Augmented Guidance) is everything under [.github/](../../.github/) that customises how Copilot — or any LLM-driven coding agent — works in this repository: the system prompt, agents, skills, prompts, and supporting tooling.

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [File-Type Catalog](#2-file-type-catalog)
3. [Discovery Flow](#3-discovery-flow)
4. [Six-Persona Model](#4-six-persona-model)
5. [Validator & Tooling](#5-validator--tooling)
6. [Authoring Guides](#6-authoring-guides)
7. [End-of-Session CAG Sweep Contract](#7-end-of-session-cag-sweep-contract)
8. [Glossary](#8-glossary)

---

## 1. Philosophy

Lurek2D is built **AI-first**. The engine itself has no embedded visual editor (binding constraint **A-01**); games, levels, scripts, assets, tests, and even the engine's own source are produced by humans **prompting agents** that write code, edit files, and run tools. The CAG layer is the contract that makes those agents predictable.

Three principles fall out of that:

1. **GitOps, no GUI.** Every CAG artifact is a plain Markdown file with YAML frontmatter. The merge gate is [tools/validate/cag_validate.py](../../tools/validate/cag_validate.py); the audit trail is `git log` plus per-session `work/<session>/logs/agent_log.jsonl`.
2. **Discovery-driven, not encyclopaedic.** The system prompt does not list every agent or skill. It teaches the agent **how to find them on demand** by matching task intent against frontmatter (`description`, `mission`, `expected_agent`). This keeps the always-loaded context small and lets the layer scale to dozens of skills without bloating every request.
3. **Model-agnostic.** Nothing in the CAG layer assumes a specific model family. Claude, GPT, Gemini, and local models that honour Markdown system prompts all consume the same files.

The system serves **six personas** — EngDev, GameDev, Modder, Player, GameTest, EngTest. Every agent declares which personas it serves; coverage is audited automatically (see §4).

**Where to start reading:** the slim system prompt at [.github/copilot-instructions.md](../../.github/copilot-instructions.md), then the five authoring templates in [work/cag-system-overhaul-20260418/reports/standards/](../../work/cag-system-overhaul-20260418/reports/standards/).

---

## 2. File-Type Catalog

The CAG layer is built from five artifact types. Each has a fixed location, required frontmatter, required body sections, and a numeric range of validator rules so violations are easy to grep.

| Type               | Location                                                                 | Purpose                                                                                                               | Required Frontmatter                                                                                      | Required Sections                                                                                                      | Line Cap            | Validator Rules               |
| ------------------ | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------------------------- |
| **System prompt**  | [.github/copilot-instructions.md](../../.github/copilot-instructions.md) | High-level discovery index, always loaded into every chat session.                                                    | (top-level config — no frontmatter)                                                                       | Engine Identity / Binding Constraints / Cross-Artifact Sync / Discovery Directives / Quality Gates / Repository Layout | ≤ 120 lines, ≤ 8 KB | E001–E004, W005               |
| **Agent**          | `.github/agents/<name>.agent.md`                                         | Defines a workflow specialist (mission, scope, IO, routing).                                                          | `name`, `mission`, `personas[]`, `primary_skills[]`, `secondary_skills[]`, `routes_to[]`, `loads_tools[]` | Mission / Scope / Inputs / Outputs / Workflow / Routing Table / Anti-patterns                                          | ≤ 200 lines         | E101–E107, W108               |
| **Skill**          | `.github/skills/<name>/SKILL.md`                                         | Deep domain knowledge pulled in only when the task matches. **No fenced code blocks** — extracted to companion files. | `name`, `description` (load-when + skip-for), `companion_files[]`, `related_skills[]`                     | Mission / When To Load / When To Skip / Domain Knowledge / Companion File Index / References                           | ≤ 120 lines         | E201–E205, W206               |
| **Prompt**         | `.github/prompts/<verb>-<noun>.prompt.md`                                | Concrete user-invocable task, typically run via `/<name>`.                                                            | `description`, `mode`, `loads_skills[]`, `loads_tools[]`, `expected_agent`, `inputs_required[]`           | Goal / Inputs / Steps / Success Criteria / Anti-patterns / Example Invocation                                          | none                | E301–E305, W306               |
| **Companion file** | `.github/skills/<name>/{examples,templates,snippets}/...`                | Code, templates, or extended notes referenced from a `SKILL.md`.                                                      | n/a                                                                                                       | n/a                                                                                                                    | none                | E203 (referenced-but-missing) |
| **Agent README**   | [.github/agents/README.md](../../.github/agents/README.md)               | Cross-agent contracts: routing, handoff schema, families.                                                             | (free-form)                                                                                               | (free-form)                                                                                                            | suggested ≤ 150     | none                          |

Why each type exists:

- The **system prompt** is the only file guaranteed to be in context. It must therefore be small and contain only what every agent needs every time: hard constraints, the cross-artifact sync table, and pointers to where richer context lives.
- **Agents** capture the *role* — what work an embodied model is responsible for. They are routed to (by `Manager`, by another agent, or directly by the user via mode selection).
- **Skills** capture *knowledge* — patterns, conventions, gotchas. They are loaded by the agent matching the user's task against the skill's `description`. The "no fenced code blocks" rule (E201) is what keeps skills readable: code lives in companions so the SKILL.md stays a navigable index.
- **Prompts** are the user's entry points. They turn a fuzzy goal ("regenerate API docs") into a deterministic procedure with verifiable success criteria.
- **Companion files** keep code samples close to the skill that owns them while letting the SKILL.md respect the 120-line cap.

---

## 3. Discovery Flow

A cold-start agent — given only the system prompt — discovers the rest of the layer by following the **Discovery Directives** section. The path looks like this:

```
User request
     │
     ▼
.github/copilot-instructions.md    (system prompt — always loaded)
     │
     ├── Engine Identity + Binding Constraints  (always in context)
     │
     ├── Cross-Artifact Sync table              (which docs to update when code changes)
     │
     ├── Discovery Directives ──────────────────────────────────────────┐
     │                                                                  │
     │  task is a domain question / pattern / convention                │
     │       │                                                          │
     │       ▼                                                          │
     │  match user intent against .github/skills/<name>/SKILL.md        │
     │  `description` frontmatter (shaped: "Load when X. Skip for Y.")  │
     │       │                                                          │
     │       └── load matched skill(s) → follow Companion File Index    │
     │                                                                  │
     │  task is a multi-step workflow / role                            │
     │       │                                                          │
     │       ▼                                                          │
     │  match task type to .github/agents/<name>.agent.md `mission`     │
     │       │                                                          │
     │       └── agent loaded → its Workflow may chain to other agents  │
     │           via the `routes_to` field                              │
     │                                                                  │
     │  task came from a slash command / user button                    │
     │       │                                                          │
     │       ▼                                                          │
     │  .github/prompts/<verb>-<noun>.prompt.md drives the run, named   │
     │  in `expected_agent`                                             │
     │                                                                  │
     └── Quality Gates  (what must pass before commit)
```

Three properties hold:

- **The system prompt is the only file always loaded.** Everything else is pulled in by intent matching, not by inclusion.
- **Skills are knowledge, not procedures.** They are additive — a single task may load several (e.g. `lua-api-design` + `lua-rust-bridge` + `testing-rust` for a new `lurek.*` API).
- **Agents are roles, not menus.** When work spans ≥ 3 agents or ≥ 5 files, the user (or a calling agent) routes to `Manager` first; Manager engages `Planner` before any implementation begins.

**Worked example** — "fix a crash in `src/physics/`":
load skills `dev-debugging` + `module-architecture` + `error-handling` → route to `Debugger` → handover to `Developer` for the fix → `Tester` for the regression test → `Reviewer` to gate the commit.

---

## 4. Six-Persona Model

Every agent declares ≥ 1 persona in its frontmatter. The personas describe **who the engine ultimately serves**, and by extension who each agent is helping when it acts:

- **EngDev** — engine contributors writing Rust core code, refactoring modules, tuning the build.
- **GameDev** — game authors using the `lurek.*` Lua API in `content/games/` and `content/demos/`.
- **Modder** — third-party Lua authors building reusable libraries under `library/` or plugins under `content/plugins/`.
- **Player** — end users running shipped games; cares about stability, UX, accessibility, install size.
- **GameTest** — QA writing Lua tests in `tests/lua/` and validating game-level behaviour.
- **EngTest** — engine-test engineers writing Rust unit/integration/fuzz tests, performance benches, and security checks.

The agent × persona matrix below is generated from the agents' frontmatter by [tools/audit/cag_persona_matrix.py](../../tools/audit/cag_persona_matrix.py); regenerate with `python tools/audit/cag_persona_matrix.py --format markdown`.

| Agent           | EngDev | GameDev | Modder | Player | GameTest | EngTest | total |
| --------------- | :----: | :-----: | :----: | :----: | :------: | :-----: | ----: |
| `architect`     |   ✅    |    ❌    |   ❌    |   ❌    |    ❌     |    ❌    |     1 |
| `audio-eng`     |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `cag-architect` |   ✅    |    ✅    |   ✅    |   ❌    |    ✅     |    ✅    |     5 |
| `configurator`  |   ❌    |    ✅    |   ✅    |   ❌    |    ❌     |    ❌    |     2 |
| `debugger`      |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ✅    |     3 |
| `developer`     |   ✅    |    ❌    |   ❌    |   ❌    |    ❌     |    ❌    |     1 |
| `doc-writer`    |   ✅    |    ✅    |   ✅    |   ❌    |    ❌     |    ❌    |     3 |
| `hacker`        |   ❌    |    ❌    |   ❌    |   ❌    |    ✅     |    ✅    |     2 |
| `lua-designer`  |   ❌    |    ✅    |   ✅    |   ❌    |    ❌     |    ❌    |     2 |
| `manager`       |   ✅    |    ❌    |   ❌    |   ❌    |    ❌     |    ❌    |     1 |
| `optimizer`     |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `physicist`     |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `planner`       |   ✅    |    ❌    |   ❌    |   ❌    |    ❌     |    ❌    |     1 |
| `player`        |   ❌    |    ✅    |   ❌    |   ✅    |    ✅     |    ❌    |     3 |
| `renderer`      |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `research`      |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `reviewer`      |   ✅    |    ✅    |   ❌    |   ❌    |    ❌     |    ❌    |     2 |
| `security`      |   ✅    |    ❌    |   ❌    |   ❌    |    ✅     |    ✅    |     3 |
| `solver`        |   ✅    |    ❌    |   ❌    |   ❌    |    ❌     |    ❌    |     1 |
| `tester`        |   ✅    |    ❌    |   ❌    |   ❌    |    ✅     |    ✅    |     3 |

| Persona    | Agents serving |
| ---------- | -------------: |
| `EngDev`   |             16 |
| `GameDev`  |             12 |
| `Modder`   |              4 |
| `Player`   |              1 |
| `GameTest` |              5 |
| `EngTest`  |              5 |

**Interpretation.** EngDev and GameDev are well covered, as expected for a game-engine project. Modder coverage (4) is intentionally narrow — most Modder needs are served indirectly via `lua-designer`, `doc-writer`, `configurator`, and the Lunasome libraries themselves. **Player** coverage is deliberately low: only the `player` agent acts on Player's behalf (smoke-testing demos, validating UX). The matrix's `WARN — low coverage` line for Player is acknowledged — Player's needs are mostly served by *what the engine already does*, not by agents writing code.

Two boundary cases are documented in their respective Anti-patterns:

- **`hacker` vs `security`** — `hacker` runs adversarial probes (fuzz, sandbox escape attempts); `security` writes the defences. Hacker must not silently patch the issue it found.
- **`player` vs `reviewer`** — `player` validates from outside (does the game feel right?); `reviewer` validates from inside (does the diff meet quality gates?). Player must not gate commits.

---

## 5. Validator & Tooling

Four Python tools maintain the layer. All are pure stdlib (no extra dependencies) and live in `tools/validate/` and `tools/audit/`.

### `tools/validate/cag_validate.py`

The merge gate. Walks every CAG file and checks frontmatter, required sections, line caps, and reference targets.

```pwsh
python tools/validate/cag_validate.py                 # full report (errors + warnings)
python tools/validate/cag_validate.py --baseline      # gate against regressions only
python tools/validate/cag_validate.py --format text   # human-readable text (default JSON)
python tools/validate/cag_validate.py --type skill    # restrict to one artifact type
```

Exit code is non-zero on any error. `--baseline` compares against the recorded baseline at the time the layer was last green and only fails on **new** violations — useful when adopting the validator on a partially-conformant repo. As of P6 the layer is at 0 errors / 0 warnings, so `--baseline` and strict mode behave identically.

**Rule index.**

| Range                | Type          | Meaning                                                                                                                                                                                                                                                                                                         |
| -------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **E001–E004 / W005** | System prompt | E001 missing required section · E002 oversize (lines or bytes) · E003 invalid YAML/structure · E004 missing canonical reference · W005 broken markdown link target                                                                                                                                              |
| **E101–E107 / W108** | Agent         | E101 missing required frontmatter field · E102 missing required body section · E103 oversize · E104 invalid persona name · E105 unknown skill in `primary_skills`/`secondary_skills` · E106 unknown agent in `routes_to` · E107 unknown tool in `loads_tools` · W108 routing-table row references unknown agent |
| **E201–E205 / W206** | Skill         | E201 forbidden fenced code block · E202 missing required body section · E203 companion file referenced but missing · E204 invalid `description` (lacks load-when + skip-for clauses) · E205 missing required frontmatter field · W206 oversize                                                                  |
| **E301–E305 / W306** | Prompt        | E301 missing required frontmatter field · E302 missing required body section · E303 unknown skill in `loads_skills` · E304 unknown tool in `loads_tools` · E305 unknown agent in `expected_agent` · W306 broken markdown link                                                                                   |

### `tools/audit/cag_link_check.py`

Resolves every Markdown link in the CAG layer to a real file (or a fragment within one). Run before commits that touch many files at once:

```pwsh
python tools/audit/cag_link_check.py --strict
python tools/audit/cag_link_check.py --strict --file docs/architecture/cag-system.md
```

`--strict` treats anchor mismatches as errors. Output is one line per broken link: `<source>:<line> -> <target> [reason]`.

### `tools/audit/cag_coverage.py`

Reports required-section presence per file as a percentage. Useful when adopting a new template or after bulk refactors.

```pwsh
python tools/audit/cag_coverage.py --type skill --threshold 100
```

Exit non-zero when coverage falls below the threshold.

### `tools/audit/cag_persona_matrix.py`

Builds the §4 matrix from agent frontmatter and warns on personas served by fewer than three agents.

```pwsh
python tools/audit/cag_persona_matrix.py --format markdown
python tools/audit/cag_persona_matrix.py --format json
```

**When to run what:**

- Per-commit (developer machine): `cag_validate.py --baseline`.
- Per-phase in a multi-phase session: `cag_validate.py` (full) + `cag_link_check.py --strict`.
- Release gate (P10 of any session that touched `.github/`): all four, all green.
- After adding/removing an agent: `cag_persona_matrix.py` to confirm no persona drops below coverage.

---

## 6. Authoring Guides

### 6.1 Adding a new agent

1. Decide the role; pick a single-word lowercase `<name>` (e.g. `profiler`).
2. Copy [work/cag-system-overhaul-20260418/reports/standards/AGENT_TEMPLATE.md](../../work/cag-system-overhaul-20260418/reports/standards/AGENT_TEMPLATE.md) to `.github/agents/<name>.agent.md`.
3. Fill the YAML frontmatter: `name`, `mission` (1 sentence), `personas` (≥ 1 from EngDev / GameDev / Modder / Player / GameTest / EngTest), `primary_skills`, `secondary_skills`, `routes_to`, `loads_tools`. Every referenced skill, agent, and tool must already exist.
4. Write the seven body sections in order: **Mission · Scope · Inputs · Outputs · Workflow · Routing Table · Anti-patterns**. Keep total length ≤ 200 lines.
5. Add a row to the agent directory table in [.github/agents/README.md](../../.github/agents/README.md).
6. Validate: `python tools/validate/cag_validate.py --type agent`.
7. Commit: `chore(cag): add <name> agent`.

### 6.2 Adding a new skill

1. Pick a single-word lowercase `<name>` matching the domain (e.g. `shader-debugging`).
2. Create `.github/skills/<name>/`. Copy [work/cag-system-overhaul-20260418/reports/standards/SKILL_TEMPLATE.md](../../work/cag-system-overhaul-20260418/reports/standards/SKILL_TEMPLATE.md) into `SKILL.md`.
3. Fill the YAML frontmatter. The `description` MUST be shaped *"Load this skill when X. Skip it for Y."* — both clauses are checked by E204.
4. Write the six body sections: **Mission · When To Load · When To Skip · Domain Knowledge · Companion File Index · References**. Cap at 120 lines.
5. **Do not include fenced code blocks in `SKILL.md`** (E201). Move every snippet to a companion file under `examples/`, `templates/`, or `snippets/`. Reference it from the body and list it under Companion File Index. Long-form notes that would push the SKILL.md over the cap go to `snippets/extended-notes.md`.
6. Validate: `python tools/validate/cag_validate.py --type skill`.
7. Optionally add a `.github/prompts/<verb>-<noun>.prompt.md` so the skill is discoverable via slash command (otherwise it stays "orphan" — loaded only when an agent matches the description on its own).

### 6.3 Adding a new prompt

1. Filename: `<verb>-<noun>.prompt.md` (e.g. `audit-coverage.prompt.md`).
2. Copy [work/cag-system-overhaul-20260418/reports/standards/PROMPT_TEMPLATE.md](../../work/cag-system-overhaul-20260418/reports/standards/PROMPT_TEMPLATE.md).
3. Fill frontmatter: `description`, `mode`, `loads_skills`, `loads_tools`, `expected_agent`, `inputs_required`. The `expected_agent` must exist; every skill and tool listed must exist (E303 / E304 / E305).
4. Write **Goal · Inputs · Steps · Success Criteria · Anti-patterns · Example Invocation**. Each Steps item should reference a skill or tool via Markdown link, e.g. `1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) and ...`. Success criteria must be binary (pass/fail).
5. Validate: `python tools/validate/cag_validate.py --type prompt`.
6. Commit: `chore(cag): add /<verb>-<noun> prompt`.

### 6.4 Adding a new tool

1. Place the script under the appropriate `tools/<subdir>/` (`validate/`, `audit/`, `fix/`, `docs/`, `dev/`, `demos/`, `dist/`, `github/`, `assets/`).
2. Add a module docstring describing inputs, outputs, and exit codes.
3. Add a row to `tools/<subdir>/README.md` and to [tools/README.md](../../tools/README.md) if it warrants a top-level mention.
4. Reference the tool from at least one agent's `loads_tools` or one prompt's `loads_tools`, otherwise it remains an orphan and will be flagged by future audits.
5. Commit: `chore(tools): add tools/<subdir>/<name>.py`.

---

## 7. End-of-Session CAG Sweep Contract

Every multi-agent session closes with a **CAG sweep** routed to `cag-architect`. The sweep answers four questions:

1. **Did this session change any CAG file** (system prompt, agent, skill, prompt, companion)? If yes — `python tools/validate/cag_validate.py` MUST be green and `python tools/audit/cag_link_check.py --strict` MUST report 0 broken links.
2. **Did this session add a new tool** under `tools/`? If yes — is it referenced from at least one agent's `loads_tools` or one prompt's `loads_tools`? If not, file a follow-up or wire it in now.
3. **Did the session reveal a missing skill or prompt?** Symptoms: an agent re-derived the same convention twice, the user had to paste the same context manually, a workflow had no slash-command entry point. If yes — author the skill/prompt now (Authoring Guides §6) or open a roadmap entry.
4. **Did the session introduce a persona-relevant capability** (e.g. a new Lua API for Modders) without updating the persona-serving agent? If yes — update the agent's `personas` array and re-run `cag_persona_matrix.py`.

Any "yes" without remediation is a session-level blocker. The sweep records its result by appending one JSONL entry to `work/<session>/logs/agent_log.jsonl`:

```json
{"timestamp":"2026-04-18T18:42:11Z","agent":"cag-architect","session":"cag-system-overhaul-20260418","phase":"sweep","skills_used":["cag-workflow","tools-cag-validation"],"result":"PASS","findings":["follow-up: add /audit-coverage prompt","tool tools/audit/foo.py is now referenced from prompt /run-quality-sweep"],"handover_to":"manager"}
```

`result` is `PASS`, `FAIL`, or `BLOCKED`. `findings` lists every action taken or filed. The next agent (typically `manager`) reads the latest sweep entry to decide whether the session can be closed.

---

## 8. Glossary

- **CAG** — Context Augmented Guidance: the `.github/` layer that customises Copilot for this repo.
- **Agent** — A workflow specialist defined under `.github/agents/<name>.agent.md`; an executing model embodies one agent at a time.
- **Skill** — On-demand domain knowledge under `.github/skills/<name>/`, loaded when the user's task matches the `description`.
- **Prompt** — A user-invocable task playbook under `.github/prompts/`, typically launched via `/<name>`.
- **System prompt** — `.github/copilot-instructions.md`; the only CAG file always in context.
- **Persona** — One of six target user profiles served by the engine and CAG layer (EngDev, GameDev, Modder, Player, GameTest, EngTest).
- **Plugin** — A Lurek2D Rust crate (or Cargo feature) that provides an optional engine subsystem with a `lurek.<namespace>` Lua surface. Tiered as CORE-KEEP / TIER-1-PLUGIN / TIER-2-PLUGIN / THIRD-PARTY-PLUGIN per `docs/architecture/plugins.md`. Pure-Lua libraries under `library/` are NOT plugins in this sense.
- **Handover** — A structured packet (bullets in a routing-table row) passed between agents at a routing boundary.
- **Handbook** — Contributor and game-author onboarding manual at `docs/handbook.md`. Pair with `docs/architecture/README.md` for navigation; pair with `docs/specs/` for module-level reference.
- **Routing** — The decision an agent makes to delegate the next step to another agent via its `routes_to` field.
- **Gate** — A binary check (e.g. `cargo test`, `cag_validate.py`) that must pass before a phase or commit is accepted.
- **Sweep** — The end-of-session CAG-Architect review (§7).
- **Baseline** — A snapshot of the violation set at the time the validator went green; `--baseline` mode fails only on regressions against it.
- **Companion file** — A code, template, or extended-notes file under a skill folder, referenced from `SKILL.md` instead of being inlined.
- **Work folder** — A `work/<session>/` directory that holds all artifacts of a multi-phase session: `scripts/`, `handovers/`, `reports/`, `data/`, `examples/`, `other/`, `temp/`, `logs/`.
- **JSONL log** — Append-only newline-delimited JSON at `work/<session>/logs/agent_log.jsonl`; one entry per completed phase, never overwritten.
