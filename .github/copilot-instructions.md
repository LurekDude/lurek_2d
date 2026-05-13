# Lurek2D System Prompt

## Communication
- Use simple English. No slang, idioms, or metaphors. Be direct and literal.
- When instructions are ambiguous, ask clarifying questions instead of guessing.
- **Always complete user requests. Responsiveness > token cost.**
- Validate with tools before returning: run tests, compile, check files. Don't guess.
- Define jargon when needed. Respond in Polish if user writes in Polish.

## Engine Identity
- Lurek2D is a single-binary 2D Rust runtime for Lua game scripts.
- Core stack: Rust stable 1.78+, LuaJIT via mlua 0.9, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9.
- License: MIT. Target personas: EngDev, GameDev, Modder, GameTest, EngTest.

## Binding Constraints
- T-01 Architecture: Five module groups (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration).
- T-02 No cycles, ever. The composition root is one-way.
- A-01 Runtime only. No embedded editor or IDE. The VS Code extension is an opt-in developer experience layer, not part of the engine binary.
- A-02 Desktop only. No mobile. No WASM.
- A-03 2D graphics only. Raycasting and isometric use 2D draw calls. No 3D pipeline.
- A-04 No platform SDKs like Steam or Epic in the core binary.
- B-01 LuaJIT is the main runtime. lua54 is a non-shipping fallback for CI where LuaJIT is unavailable.
- B-02 wgpu 22 is the only renderer backend. No OpenGL path.
- B-03 Target 60 FPS at 1080p on integrated GPUs.
- B-04 Use Rust threads for concurrency. LuaJIT VMs do not share state. Use typed MPMC Channel for cross-VM communication.
- B-05 Use TOML for human config. Use JSON only for external interop. No YAML.
- C-01 Use lurek.* only. No bare globals, no engine-prefixed names, no alternative top-level tables.
- TST-01 lurek.* behavior → tested in tests/lua/. Rust tests must not duplicate Lua-reachable coverage.
- TST-02 No #[cfg(test)] in src/. Rust unit tests → tests/rust/unit/<module>_tests.rs.
- TST-03 src/lua_api/<module>_api.rs: bindings only. Business logic stays in src/<module>/ as pure Rust.
- TST-04 Every mod.rs: only pub mod, pub use, attributes, and doc comments. Definitions in sibling files.
- TST-05 Demo tests → tests/lua/demos/test_<name>.lua. Screenshot demos → tests/demo_smoke_tests.rs with #[ignore].
- TST-06 One test file per module per layer: test_<module>_<layer>.lua.
- **Never edit docs/api/lurek.lua** — auto-generated. Fix at source (`src/lua_api/*_api.rs`), then regenerate with `python tools/gen_all_docs.py`.
- **Never add warning suppressions** to .vscode/settings.json to hide problems.

## Cross-Artifact Sync
Update all linked artifacts in the same commit:
- Change `src/<module>/*.rs` → update `docs/specs/<module>.md`.
- Change `src/lua_api/<module>_api.rs` → update `docs/specs/<module>.md`; regenerate API outputs with `python tools/gen_all_docs.py`.
- Add, rename, or remove `lurek.*` API → update `content/examples/`, affected `content/games/`, and dependent `library/` modules.
- Create a new module → add `docs/specs/<module>.md` and update `docs/specs/README.md`.
- Change `library/<name>/init.lua` → update its `example.lua`, tests, harness registration, and regenerate library docs.
- Change onboarding, build steps, or quality gates → update `docs/handbook.md` and `CONTRIBUTING.md`.
- Add a demo in `content/games/` → update the matching test, smoke test, and harness registration.
- Any change → update `docs/CHANGELOG.md`.

## Discovery Directives

**Architecture & CAG source of truth:**
- `docs/architecture/philosophy.md` — full design assumptions, module groups, and binding constraint rationale.
- `docs/architecture/cag-system.md` — CAG file types, WHY/HOW/WHAT layer doctrine, worked examples, and validator contract.
- `docs/architecture/cag-system.md § 4.1` — authoritative agent-to-skill bundle table (derived from each agent's CAG Metadata).
- `.github/agents/README.md` — cross-agent routing, ownership, and handoff contracts.

**CAG layer — how to find the right context:**
- Layer intent: **Agents → WHY** (scope, ownership, mission) · **Skills → HOW** (domain knowledge, patterns) · **Prompts → WHAT** (concrete steps, output criteria). A prompt must not duplicate a skill or agent workflow.
- Agents in `.github/agents/<name>.agent.md`: match task to `mission`; route with `routes_to`; prefer the smallest valid agent set.
- Skills in `.github/skills/<name>/SKILL.md`: match task to `description` (load-when + skip-for); load all relevant skills before acting.
- Prompts in `.github/prompts/<verb>-<noun>.prompt.md`: `agent` field is required; use `/route-prompt` to find the best prompt for any request.
- Agents are autonomous — they work until done, blocked, or out of scope, then return to Manager. Single-agent mode: complete requests directly. Multi-agent mode: Manager routes; load `manager.agent.md` + `agent-routing` skill.

**Key references:**
- `docs/architecture/test-framework.md` — test placement rules and Lua-vs-Rust decision tree.
- `docs/specs/README.md` — module-spec catalog: where to add or rename specs.
- `tools/README.md` — tool inventory: generators, validators, audits.
- `docs/handbook.md` — contributor workflow, setup, and quality expectations.

## Work Session
Every agent uses `work/<session-name>/` as a temporary workspace. This keeps in-progress artifacts out of source history.

Standard layout: `plans/` (task breakdown) · `briefs/` (research, repros) · `reports/` (findings, audit results) · `logs/` (agent_log.jsonl).

Rules:
- Any agent may write session artifacts; scope limits only product-source ownership.
- Append one JSONL line per completed phase to `logs/agent_log.jsonl`.
- Move finished sessions to `work/archive/`.

## Quality Gates
Run before every commit:
- `cargo test` and `cargo clippy -- -D warnings` — zero failures, zero warnings.
- `python tools/validate/cag_validate.py` — for any `.github/` changes; use `--baseline` if needed.
- `python tools/audit/cag_link_check.py --strict` — when CAG links or file paths change.
- Agent-specific audits (coverage, doc, persona matrix) are listed in each agent's Workflow section.

## Git Hygiene
- Confirm the branch with `git rev-parse --abbrev-ref HEAD`. Read-only inspection (status, diff, log, blame) is always allowed.
- Do not stop work because of unrelated or pre-existing worktree changes. Continue the requested task and ignore files outside your scope unless the user explicitly asks for investigation.
- Stage only touched files. Never use `git add .`.
- Commit format: `type(scope): description`. Allowed types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. One logical change per commit.
- Every commit must add or extend the current version entry in `docs/CHANGELOG.md`. MAJOR/MINOR changes also update `Cargo.toml`.

## Repository Layout
- `src/` — Rust engine modules; `src/lua_api/` = bindings only, business logic stays in `src/<module>/`.
- `tests/` — Rust test targets and the Lua test harness.
- `docs/` — specs, architecture, API references; `docs/api/` is generated — never edit by hand.
- `content/` — examples, game demos, UI layouts, plugins. `library/` — reusable Lua game-logic modules.
- `.github/` — CAG layer: agents, skills, prompts, and this file. `tools/` — generators, validators, audit scripts.
- `work/` — agent session workspaces (temp; not committed to main history). `logs/` — runtime logs, validate output.

