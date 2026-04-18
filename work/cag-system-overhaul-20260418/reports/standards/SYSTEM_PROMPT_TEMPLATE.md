# SYSTEM PROMPT TEMPLATE — `.github/copilot-instructions.md`

**Applies to**: the single root system prompt file `.github/copilot-instructions.md`.
**Audience**: every Copilot agent on cold start. Always loaded.
**Authoring agent**: CAG-Architect.

---

## Hard Caps

| Metric          | Limit         | Current state (P0) |
|-----------------|---------------|--------------------|
| Lines           | **≤ 120**     | 297                |
| Bytes           | **≤ 8 KB**    | 25 KB              |
| Fenced blocks   | ≤ 3 (only for the sync table example or critical commands) | many |
| Inline rosters  | **0** (no agent list, no skill catalog, no prompt list) | full rosters inlined |

The system prompt is a **discovery index**, not a manual. If a fact can be re-derived by listing `.github/agents/` or `.github/skills/`, it does **not** belong here.

---

## Required Sections (in this exact order)

1. **Engine Identity** — one paragraph naming Lurek2D, the languages (Rust + LuaJIT via mlua), the binary deliverable type (desktop runtime), and the license (MIT).
2. **Binding Constraints** — verbatim list of A-01..A-04 and B-01..B-05 from `docs/architecture/philosophy.md`. No paraphrasing. No additions.
3. **Cross-Artifact Sync Table** — the canonical "if you change X, you must also update Y" table (Rust source ↔ docs/specs ↔ Lua API ↔ examples ↔ CHANGELOG).
4. **Discovery Directives** — how to find agents (`.github/agents/<name>.agent.md`, frontmatter `mission` / `personas`), how to find skills (`.github/skills/<name>/SKILL.md`, load when the `description` matches the task), how to find prompts (`.github/prompts/`), and how to find tools (`tools/<sub>/README.md`).
5. **Pointer to `docs/architecture/cag-system.md`** — single sentence: "For the full CAG system reference (philosophy, file types, persona model, validator rules, authoring guides), read `docs/architecture/cag-system.md`."
6. **Quality Gates** — the minimum gate (`cargo test && cargo clippy -- -D warnings` + `python tools/validate/cag_validate.py`) and where to find the rest (`tools/audit/README.md`).
7. **Repository Layout** — compact 10–15 line tree, top-level only (`src/`, `tests/`, `docs/`, `tools/`, `.github/`, `content/`, `extensions/`, `work/`).

---

## Forbidden Content

- Inline agent roster or table.
- Inline skill catalog (full list of 32 skill names).
- Inline prompt list.
- Generic Rust advice (idioms, common patterns, "use `Result`").
- Restating common conventions already in `rustfmt`, `clippy`, or any standard style guide.
- Tier/group long-form descriptions (those live in `docs/architecture/engine-architecture.md`).
- Detailed CLI tool catalogs (those live in `tools/README.md` and per-subfolder READMEs).

---

## Reference Implementation (compliant skeleton ~80 lines)

```markdown
# Lurek2D Engine — System Prompt

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game scripts via LuaJIT (mlua 0.9). Desktop only (Windows / Linux / macOS, x86_64 + ARM). MIT licensed. Single binary distribution. No GUI editor.

## Binding Constraints

Verbatim from `docs/architecture/philosophy.md`. Do not propose changes without a design-assumption update.

- **A-01** Runtime only — no embedded visual editor or IDE
- **A-02** Desktop only — no mobile, no WASM
- **A-03** 2D graphics only
- **A-04** No distribution platform SDKs in the core binary
- **B-01** LuaJIT primary; `lua54` is non-shipping fallback
- **B-02** wgpu 22 only renderer backend
- **B-03** 60 FPS at 1080p on integrated GPUs
- **B-04** Concurrency in Rust threads; LuaJIT VMs cannot share state
- **B-05** TOML for human config; JSON for interop only

## Cross-Artifact Sync

When you change one of these, you MUST update the others in the same commit.

| Changed                                  | Also update                                    |
|------------------------------------------|------------------------------------------------|
| `src/<module>/*.rs`                      | `docs/specs/<module>.md`                       |
| `src/lua_api/<module>_api.rs`            | `docs/specs/<module>.md` · `docs/API/lua-api.md` |
| `lurek.*` API added/renamed/removed      | `content/examples/<module>.lua` · affected demos |
| New module created                       | New `docs/specs/<module>.md` · `docs/specs/README.md` |
| Any change                               | `docs/CHANGELOG.md`                            |

## Discovery

- **Agents** — `.github/agents/<name>.agent.md`. Read frontmatter (`mission`, `personas`, `primary_skills`, `routes_to`) to choose one.
- **Skills** — `.github/skills/<name>/SKILL.md`. Load when the `description` field's trigger conditions match your task. Skip when its skip conditions match.
- **Prompts** — `.github/prompts/<verb>-<noun>.prompt.md`. User-selected entrypoints.
- **Tools** — `tools/<sub>/README.md` lists scripts per subfolder; root index is `tools/README.md`.

For the full CAG system reference (philosophy, file types, persona model, validator rules, authoring guides), read `docs/architecture/cag-system.md`.

## Quality Gates

Minimum before any commit:

```
cargo test && cargo clippy -- -D warnings
python tools/validate/cag_validate.py
```

Full quality sweep is documented in `tools/audit/README.md`.

## Repository Layout

```
src/              Rust engine source (Foundations · Core Runtime · Platform Services · Feature Systems · Edge/Integration)
tests/            Rust + Lua test suites (rust/, lua/)
docs/             Architecture, specs, generated API references, CHANGELOG
tools/            Permanent CLI scripts (validate/, audit/, fix/, docs/, dev/, demos/, dist/, github/)
content/          Lua game scripts (demos/, examples/, library/, layouts/)
.github/          CAG layer (copilot-instructions.md, agents/, skills/, prompts/)
extensions/       VS Code extension
work/             Active and archived session folders
```
```

---

## Validator Rules Summary

| Rule  | Severity | Description                                                                       |
|-------|----------|-----------------------------------------------------------------------------------|
| E001  | error    | Missing one of the 7 required sections (in correct order).                        |
| E002  | error    | File exceeds 120-line cap.                                                        |
| E003  | error    | File exceeds 8 KB cap.                                                            |
| E004  | error    | Contains a forbidden inline roster (agent table, skill catalog, prompt list).     |
| W005  | warning  | References a file that does not exist on disk (broken link).                      |
