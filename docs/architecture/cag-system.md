# Lurek2D — CAG System

Source of truth for the Context Augmented Guidance layer: everything under `.github/` that customises how Copilot and other LLM agents work in this repository.

The system prompt at [.github/copilot-instructions.md](../../.github/copilot-instructions.md) is a discovery index. This document is where agents and contributors come for full doctrine.

---

## Table of Contents

1. [Philosophy](#philosophy)
2. [File-Type Catalog](#file-type-catalog)
3. [WHY / HOW / WHAT Layer Doctrine](#why--how--what-layer-doctrine)
4. [Discovery Flow](#discovery-flow)
5. [Six-Persona Model](#six-persona-model)
6. [Agent Roster and Persona Matrix](#agent-roster-and-persona-matrix)
7. [Validator and Tooling](#validator-and-tooling)
8. [Authoring Guides](#authoring-guides)
9. [End-of-Session CAG Sweep Contract](#end-of-session-cag-sweep-contract)
10. [Glossary](#glossary)

---

## Philosophy

Lurek2D is built AI-first. There is no embedded visual editor (constraint A-01); games, levels, scripts, assets, tests, and engine source are produced by humans prompting agents that write code, edit files, and run tools. The CAG layer is the contract that makes those agents predictable.

Three principles:

1. **GitOps, no GUI.** Every CAG artefact is a plain Markdown file with YAML frontmatter. The merge gate is `tools/validate/cag_validate.py`; the audit trail is `git log` plus per-session `work/<session>/logs/agent_log.jsonl`.
2. **Discovery-driven, not encyclopaedic.** The system prompt does not list every agent or skill — it teaches the agent how to find them on demand by matching task intent against frontmatter metadata. This keeps the always-loaded context small.
3. **Model-agnostic.** Nothing in the CAG layer assumes a specific model family. Any model that honours Markdown system prompts consumes the same files.

---

## File-Type Catalog

Five artefact types, each with a fixed location, required frontmatter, required sections, and validator rule range.

| Type | Location | Purpose | Line Cap |
|------|----------|---------|---------|
| **System prompt** | `.github/copilot-instructions.md` | Discovery index — always loaded. Hard constraints + sync table + pointers to richer context. | ≤ 120 lines / ≤ 8 KB |
| **Agent** | `.github/agents/<name>.agent.md` | Workflow specialist: mission, scope, IO, workflow. | ≤ 300 lines |
| **Skill** | `.github/skills/<name>/SKILL.md` | Deep domain knowledge. Loaded when task matches `description`. No fenced code blocks. | ≤ 120 lines |
| **Prompt** | `.github/prompts/<verb>-<noun>.prompt.md` | User-invocable task playbook. Typically run via `/<name>`. | none |
| **Companion file** | `.github/skills/<name>/{examples,templates,snippets}/...` | Code/templates/extended notes for a skill. Keeps SKILL.md within the line cap. | none |

**Why the system prompt must be small:** It is the only CAG file guaranteed to be in context. Everything else is pulled in by intent matching — it scales to dozens of skills without bloating every request.

**Why no fenced code blocks in SKILL.md (rule E201):** Code lives in companion files so SKILL.md remains a navigable index.

### Required Frontmatter and Sections

**Agent** (`<name>.agent.md`):
- Frontmatter: `name`, `description`, optional `tools[]`
- Body sections (in order): Mission · Scope · Inputs · Outputs · Workflow · Success Metrics · Anti-patterns · CAG Metadata
- `## CAG Metadata` holds personas and skills (not frontmatter)

**Skill** (`SKILL.md`):
- Frontmatter: `name`, `description` (must be shaped *"Load this skill when X. Skip it for Y."*)
- Body sections: Mission · When To Load · When To Skip · Domain Knowledge · Companion File Index · References

**Prompt** (`<verb>-<noun>.prompt.md`):
- Frontmatter: `description`, `agent`, optional `tools[]`
- Body sections: Goal · Inputs · Steps · Success Criteria · Anti-patterns · Example Invocation
- `## CAG Metadata` holds: `Mode`, `Loads skills`, `Inputs required`

---

## WHY / HOW / WHAT Layer Doctrine

| File type | Layer | Core question |
|-----------|-------|--------------|
| Agent `.agent.md` | **WHY** | *Why does this role exist? What is it responsible for?* |
| Skill `SKILL.md` | **HOW** | *How do you do the work? What domain knowledge is needed?* |
| Prompt `.prompt.md` | **WHAT** | *What exact steps produce the outcome?* |

**Rules:**
- A prompt must not duplicate a skill's HOW-TO. Steps should invoke skills by name, not restate their content.
- A skill must not contain agent ownership language — that belongs in agents.
- An agent must not contain step-by-step instructions — those belong in prompts or skills.
- If a concept appears in two file types, one is wrong. Move to the canonical layer and link.

---

## Discovery Flow

```
User request
     │
     ▼
.github/copilot-instructions.md          (always loaded)
     │
     ├── Engine Identity + Binding Constraints
     ├── Cross-Artifact Sync table
     └── Discovery Directives
           │
           ├── Domain question / pattern?
           │     → match intent against SKILL.md `description`
           │     → load matched skill(s) + Companion File Index
           │
           ├── Multi-step workflow / role?
           │     → match task to agent `mission`
           │     → Manager loads `agent-routing` for handoffs
           │
           └── Slash command / user button?
                 → .github/prompts/<verb>-<noun>.prompt.md
```

Three properties hold:
- **System prompt is the only file always loaded.** Everything else is demand-pulled.
- **Skills are additive.** A single task may load several (e.g. `lua-api-design` + `lua-rust-bridge` + `testing-rust`).
- **Agents are roles.** When work spans ≥3 agents or ≥5 files, route to Manager first; Manager engages Planner before implementation.

**Worked example** — "fix a crash in `src/physics/`": load skills `dev-debugging` + `module-architecture` + `error-handling` → route to `Developer` for root-cause and fix → `Tester` for regression test → `Verifier` to gate commit.

---

## Six-Persona Model

Every agent declares ≥1 persona. Personas describe who the engine ultimately serves:

| Persona | Who |
|---------|-----|
| **EngDev** | Engine contributors writing Rust core code, refactoring modules, tuning the build |
| **GameDev** | Game authors using the `lurek.*` Lua API in `content/games/` |
| **Modder** | Third-party Lua authors building libraries in `library/` or plugins in `content/plugins/` |
| **Player** | End users running shipped games — cares about stability, UX, install size |
| **GameTest** | QA writing Lua tests in `tests/lua/`, validating game-level behaviour |
| **EngTest** | Engine-test engineers writing Rust unit/integration/fuzz tests and security checks |

---

## Agent Roster and Persona Matrix

Regenerate with `python tools/audit/cag_persona_matrix.py --format markdown`.

| Agent | EngDev | GameDev | Modder | Player | GameTest | EngTest | Total |
|-------|:------:|:-------:|:------:|:------:|:--------:|:-------:|------:|
| `architect` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | 1 |
| `build-engineer` | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | 3 |
| `cag-architect` | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | 5 |
| `content-maker` | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | 3 |
| `developer` | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | 3 |
| `doc-writer` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | 3 |
| `extension-engineer` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | 3 |
| `lua-designer` | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | 2 |
| `manager` | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | 5 |
| `planner` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | 4 |
| `tester` | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | 4 |
| `verifier` | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | 3 |

**tester vs verifier:** `tester` writes and runs test cases; `verifier` reviews finished diffs, profiles performance, issues accept/reject. Tester must not fix production code; Verifier must not write tests.

**developer vs verifier (performance):** `developer` implements a performance fix; `verifier` captures baseline, measures after, gates on data. Developer must not self-gate on performance.

---

## Validator and Tooling

### `tools/validate/cag_validate.py` — merge gate

Walks every CAG file, checks frontmatter, required sections, line caps, reference targets.

```powershell
python tools/validate/cag_validate.py                 # full report
python tools/validate/cag_validate.py --baseline      # gate against regressions only
python tools/validate/cag_validate.py --type skill    # restrict to one type
python tools/validate/cag_validate.py --format text   # human-readable (default JSON)
```

Exit code non-zero on any error.

**Validator rule index:**

| Range | Type | Key rules |
|-------|------|-----------|
| **E001–E004 / W005** | System prompt | Missing required section · oversize · invalid structure · missing canonical reference · broken link |
| **E101–E113 / W108** | Agent | Missing/malformed frontmatter · invalid persona name · unknown skill · deprecated routing · unknown tool path · exceeds line cap · missing/misordered sections · `Autonomy` wrongly present · `Success Metrics` missing star contract · thin Scope or Anti-patterns · duplicated bullets across agents |
| **E201–E205 / W206** | Skill | Forbidden code block · missing/malformed frontmatter · unknown `Related skills` · missing/misordered sections · description missing load-when/skip-for clauses |
| **E301–E307 / W306** | Prompt | Missing/malformed frontmatter · unknown skill · unknown tool · unknown agent · missing/misordered sections · `agent` field absent · Success Criteria missing checklist items |

### `tools/audit/cag_link_check.py`

Resolves every Markdown link in the CAG layer to a real file (or fragment). Run before commits touching many files:

```powershell
python tools/audit/cag_link_check.py --strict
```

Output: one line per broken link: `<source>:<line> -> <target> [reason]`.

### `tools/audit/cag_coverage.py`

Reports required-section presence per file as a percentage:

```powershell
python tools/audit/cag_coverage.py --type skill --threshold 100
```

### `tools/audit/cag_persona_matrix.py`

Builds the §5 matrix. Warns when a persona is served by fewer than three agents:

```powershell
python tools/audit/cag_persona_matrix.py --format markdown
```

**When to run what:**

| When | Run |
|------|-----|
| Per-commit | `cag_validate.py --baseline` |
| Per-phase in a multi-phase session | `cag_validate.py` (full) + `cag_link_check.py --strict` |
| Release gate | All four tools, all green |
| After adding/removing an agent | `cag_persona_matrix.py` |

---

## Authoring Guides

### Adding a new agent

1. Pick lowercase kebab-case `<name>`. Copy [docs/templates/AGENT_TEMPLATE.md](../templates/AGENT_TEMPLATE.md) to `.github/agents/<name>.agent.md`.
2. Fill YAML frontmatter: `name`, `description`, optional `tools`. Put personas and skills in `## CAG Metadata`, not frontmatter.
3. Write the seven required sections in order: Mission · Scope · Inputs · Outputs · Workflow · Success Metrics · Anti-patterns · CAG Metadata. Keep ≤ 300 lines.
4. Put routing specifics in [.github/skills/agent-routing/SKILL.md](../../.github/skills/agent-routing/SKILL.md), not in a per-agent Routing Table. `Success Metrics` must explain the 1–10 star scale with 3–6 role-specific bullets.
5. Add a row to [.github/agents/README.md](../../.github/agents/README.md).
6. Validate: `python tools/validate/cag_validate.py --type agent`. Commit: `chore(cag): add <name> agent`.

### Adding a new skill

1. Create `.github/skills/<name>/`. Copy [docs/templates/SKILL_TEMPLATE.md](../templates/SKILL_TEMPLATE.md) into `SKILL.md`.
2. `description` MUST be shaped *"Load this skill when X. Skip it for Y."* — both clauses checked by W206.
3. Six body sections: Mission · When To Load · When To Skip · Domain Knowledge · Companion File Index · References. Cap at 120 lines.
4. **No fenced code blocks in SKILL.md** (E201). Move every snippet to a companion file under `examples/`, `templates/`, or `snippets/`. Reference from body and list under Companion File Index.
5. Validate: `python tools/validate/cag_validate.py --type skill`. Commit: `chore(cag): add <name> skill`.

### Adding a new prompt

1. Filename: `<verb>-<noun>.prompt.md`. Copy [docs/templates/PROMPT_TEMPLATE.md](../templates/PROMPT_TEMPLATE.md).
2. Frontmatter: `description`, `agent`, optional `tools`. CAG Metadata: `Mode`, `Loads skills`, `Inputs required`. Every skill, agent, tool listed must exist.
3. Six body sections: Goal · Inputs · Steps · Success Criteria · Anti-patterns · Example Invocation. Steps should link loaded skills by name. Success Criteria must use checklist items.
4. Validate: `python tools/validate/cag_validate.py --type prompt`. Commit: `chore(cag): add /<verb>-<noun> prompt`.

### Editing the system prompt

1. Keep ≤ 300 lines. Move prose to `docs/architecture/philosophy.md` or a skill.
2. Binding constraints only. Each constraint has a stable code (T-xx, A-xx, B-xx, C-xx, TST-xx). Never renumber — add at end of the group.
3. Cross-artifact sync rules: any time a file type changes, the sync table updates in the same commit.
4. After any change: `python tools/validate/cag_validate.py` + `python tools/audit/cag_link_check.py --strict`. Both must exit 0.
5. Update `docs/CHANGELOG.md` in the same commit. Commit: `chore(cag): update system prompt — <summary>`.

### Adding a new tool

1. Place script under `tools/<subdir>/` (`validate/`, `audit/`, `fix/`, `docs/`, `dev/`, `demos/`, `dist/`, `github/`, `assets/`).
2. Add module docstring with inputs, outputs, exit codes.
3. Add a row to `tools/<subdir>/README.md` and [tools/README.md](../../tools/README.md).
4. Reference the tool from at least one agent's `tools` frontmatter or one prompt's `tools` frontmatter.
5. Commit: `chore(tools): add tools/<subdir>/<name>.py`.

---

## End-of-Session CAG Sweep Contract

Every multi-agent session closes with a **CAG sweep** routed to `cag-architect`. Four questions:

1. Did this session change any CAG file? If yes — `cag_validate.py` must be green + `cag_link_check.py --strict` must report 0 broken links.
2. Did this session add a new tool under `tools/`? If yes — is it referenced from at least one agent or prompt frontmatter? If not, wire it in or file a follow-up.
3. Did the session reveal a missing skill or prompt? (Symptoms: agent re-derived the same convention twice, user had to paste context manually, workflow had no slash-command entry.) If yes — author the skill/prompt or open a roadmap entry.
4. Did the session introduce a persona-relevant capability without updating the serving agent? If yes — update the agent's `personas` array and re-run `cag_persona_matrix.py`.

Any "yes" without remediation is a session-level blocker. The sweep records results by appending one JSONL entry to `work/<session>/logs/agent_log.jsonl`:

```json
{"timestamp":"2026-04-18T18:42:11Z","agent":"cag-architect","session":"cag-system-overhaul-20260418","phase":"sweep","skills_used":["cag-workflow","tools-cag-validation"],"result":"PASS","findings":["follow-up: add /audit-coverage prompt"],"handover_to":"manager"}
```

`result` is `PASS`, `FAIL`, or `BLOCKED`.

---

## Glossary

| Term | Definition |
|------|-----------|
| **CAG** | Context Augmented Guidance — the `.github/` layer that customises Copilot for this repo |
| **Agent** | A workflow specialist defined in `.github/agents/<name>.agent.md` |
| **Skill** | On-demand domain knowledge in `.github/skills/<name>/SKILL.md` — loaded when task matches |
| **Prompt** | A user-invocable task playbook in `.github/prompts/<verb>-<noun>.prompt.md` |
| **System prompt** | `.github/copilot-instructions.md` — the only CAG file always in context |
| **Persona** | One of six target user profiles: EngDev, GameDev, Modder, Player, GameTest, EngTest |
| **Companion file** | Code/template/extended-notes file under a skill folder; referenced from SKILL.md |
| **Handover** | A structured packet passed between agents at a routing boundary |
| **Gate** | A binary check (`cargo test`, `cag_validate.py`) that must pass before a phase or commit |
| **Sweep** | End-of-session CAG-Architect review |
| **Baseline** | Snapshot of validator violations at the time the layer went green; `--baseline` fails only on regressions |
| **Work folder** | `work/<session>/` — temporary artefacts for a multi-phase session; not committed to main |
| **JSONL log** | Append-only `work/<session>/logs/agent_log.jsonl` — one entry per completed phase |
