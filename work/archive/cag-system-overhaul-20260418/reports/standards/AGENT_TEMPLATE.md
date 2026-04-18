# AGENT TEMPLATE — `.github/agents/<name>.agent.md`

**Applies to**: every agent definition file under `.github/agents/`.
**Audience**: the agent runtime (Copilot) routing into the agent + human contributors authoring agents.
**Authoring agent**: CAG-Architect (with domain agent review for specialist agents).

---

## Hard Cap

- **≤ 200 lines** per agent file.
- Filename must match frontmatter `name` (case-insensitive, kebab-case): `developer.agent.md` ↔ `name: Developer`.

---

## Required Frontmatter (YAML, fenced with `---`)

```yaml
---
name: AgentName
mission: "One-sentence mission statement, ends with a period."
personas: [EngDev, GameDev, Modder, Player, GameTest, EngTest]
primary_skills: [skill-name-1, skill-name-2]
secondary_skills: [skill-name-3]
routes_to: [OtherAgent1, OtherAgent2]
loads_tools: [tools/audit/foo.py, tools/validate/bar.py]
---
```

**Field rules**:

- `name` — PascalCase or hyphenated PascalCase (`Lua-Designer`). Must match filename stem with `.agent.md` stripped, hyphens preserved, case-insensitive.
- `mission` — exactly one sentence, ≤ 140 characters, ends with period.
- `personas` — list of 1–6 entries from the closed vocabulary `EngDev | GameDev | Modder | Player | GameTest | EngTest`. **Required ≥ 1**; warning if empty.
- `primary_skills` — list of skill folder names that exist under `.github/skills/<name>/`. May be empty for purely procedural agents (Manager, Planner).
- `secondary_skills` — same vocabulary as `primary_skills`. May be empty.
- `routes_to` — list of other agent `name` values that exist as `.github/agents/<name>.agent.md`. Empty allowed for terminal agents.
- `loads_tools` — list of repo-relative paths to scripts under `tools/`. Each must exist on disk.

---

## Required Body Sections (in this exact order)

1. **Mission** — expand the frontmatter `mission` into a paragraph (≤ 6 sentences). Must reference at least one persona from frontmatter.
2. **Scope** — two subsections:
   - **Owns** — bullet list of file types, directories, or decisions this agent is the source of truth for.
   - **Must Not Become** — bullet list of agent roles this agent must not absorb (anti-overlap clause).
3. **Inputs** — bullet list of artifacts the agent expects (files, prior phase outputs, user-supplied parameters).
4. **Outputs** — bullet list of artifacts the agent produces (files, reports, decisions, handover packets).
5. **Workflow** — numbered steps (3–10). Each step may reference a tool by markdown link `[tool: name](tools/.../script.py)` or a skill by `[skill: name](.github/skills/name/SKILL.md)`.
6. **Routing Table** — markdown table mapping situation → next agent. Entries must use names from frontmatter `routes_to`.
7. **Anti-patterns** — bullet list of what this agent must never do (often mirrors "Must Not Become" with sharper specifics).

---

## Forbidden Content

- Embedded long code blocks (> 10 lines). Move to a skill's `examples/` folder.
- Duplicating skill content. Reference the skill instead.
- Inline list of all other agents (use frontmatter `routes_to` only).

---

## Reference Implementation (compliant ~120-line `developer.agent.md`)

```markdown
---
name: Developer
mission: "Implement Rust engine features and bug fixes across all tiers, excluding specialist domains owned by Renderer/Physicist/Audio-Eng."
personas: [EngDev, EngTest]
primary_skills: [rust-coding, module-architecture, error-handling]
secondary_skills: [testing-rust, performance-profiling, lua-rust-bridge]
routes_to: [Tester, Reviewer, Architect, Lua-Designer]
loads_tools: [tools/validate/cag_validate.py, tools/audit/audit_module.py]
---

# Developer

## Mission

The Developer agent implements general Rust engine features for the EngDev persona and supports the EngTest persona by writing engine code that is testable and observable. It owns non-specialist subsystem code across all five module tiers (Foundations, Core Runtime, Platform Services, Feature Systems, Edge/Integration). Specialist work in the renderer, physics, audio, or Lua API surface routes out to the dedicated agent for that domain.

## Scope

### Owns
- New and modified files under `src/` outside specialist surfaces.
- Bug fixes in any Rust module not exclusively owned by another agent.
- Test additions in `tests/rust/unit/` and `tests/rust/stress/` for code it touches.

### Must Not Become
- A shadow Renderer (do not modify `src/render/` GPU pipeline code).
- A shadow Physicist (do not modify `src/physics/` rapier integration).
- A shadow Lua-Designer (do not invent new `lurek.*` API surface — request a design from Lua-Designer first).
- A shadow Doc-Writer (do not author user-facing docs in `docs/`).

## Inputs
- Issue, bug report, or roadmap phase artifact describing the change.
- Affected module's `docs/specs/<module>.md` for current contract.
- Any prior Solver or Architect handover packet.

## Outputs
- Rust source diff under `src/`.
- Updated `docs/specs/<module>.md` if module contract changed.
- Updated `docs/CHANGELOG.md` entry under the current version.
- Test additions or updates under `tests/rust/`.
- Handover packet to Tester (for new public API) or Reviewer (for completed work).

## Workflow
1. Read the affected module's [`docs/specs/<module>.md`] to understand the current contract.
2. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md) and any module-relevant skill from frontmatter `secondary_skills`.
3. Implement the change. Do not stage unrelated files.
4. Run [tool: cag_validate](tools/validate/cag_validate.py) if any `.github/` file changed.
5. Run `cargo test && cargo clippy -- -D warnings`.
6. Update `docs/CHANGELOG.md` with a one-line entry under the current version.
7. Hand over to Tester (new API) or Reviewer (completed work). Use the routing table.

## Routing Table

| Situation                                              | Next agent     |
|--------------------------------------------------------|----------------|
| New `lurek.*` API surface needed                       | Lua-Designer   |
| Module boundary or new module needed                   | Architect      |
| Implementation complete, ready for tests               | Tester         |
| Implementation + tests complete, ready for review      | Reviewer       |

## Anti-patterns
- Editing GPU code in `src/render/` — that is Renderer's surface.
- Inventing a new `lurek.*` namespace without Lua-Designer sign-off.
- `git add .` — always stage explicit files.
- Skipping the CHANGELOG update.
- Adding fenced code blocks to a SKILL.md file (skills are prose).
```

---

## Validator Rules Summary

| Rule  | Severity | Description                                                                       |
|-------|----------|-----------------------------------------------------------------------------------|
| E101  | error    | Missing or malformed YAML frontmatter.                                            |
| E102  | error    | `personas` contains a value outside the closed vocabulary.                        |
| E103  | error    | `primary_skills` or `secondary_skills` references a non-existent skill folder.    |
| E104  | error    | `routes_to` references an agent name that does not exist.                         |
| E105  | error    | `loads_tools` references a path that does not exist on disk.                      |
| E106  | error    | File exceeds 200-line cap.                                                        |
| E107  | error    | Missing one of the 7 required body sections (in correct order).                   |
| W108  | warning  | `personas` is empty (zero personas declared).                                     |
