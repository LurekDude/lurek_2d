# Lurek2D Engine — System Prompt

## Engine Identity

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game scripts via LuaJIT (`mlua` 0.9; `lua54` is a non-shipping fallback). Tech baseline: Rust stable ≥1.78, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9. Public API namespace is `lurek.*`. Desktop only (Windows / Linux / macOS, x86_64 + ARM). MIT licensed. Single-binary distribution; no embedded editor.

## Binding Constraints

Verbatim from `docs/architecture/philosophy.md`. Do not propose changes without a design-assumption update.

- **A-01** Runtime only — no embedded visual editor or IDE.
- **A-02** Desktop only — Windows / Linux / macOS, x86_64 + ARM. No mobile, no WASM.
- **A-03** 2D graphics only — raycasting (textured-quad 2.5D) and isometric use 2D draw calls.
- **A-04** No distribution platform SDKs (Steam, Epic) in the core binary.
- **B-01** LuaJIT is the primary runtime; `lua54` Cargo feature is a non-shipping fallback.
- **B-02** wgpu 22 is the only renderer backend (Vulkan / DX12 / Metal); no OpenGL path.
- **B-03** 60 FPS at 1080p target on integrated GPUs (Intel UHD, AMD APU).
- **B-04** Concurrency in Rust threads; LuaJIT VMs cannot share state — use `Channel` for cross-VM comms.
- **B-05** TOML for human-authored config; JSON for external interop only; no YAML.
- **TST-01** Lua-first testing: behaviour reachable via `lurek.*` MUST be tested in `tests/lua/` — see [philosophy.md § Testing Constraints](../docs/architecture/philosophy.md#testing-constraints).
- **TST-02** Inline `#[cfg(test)]` blocks in `src/**/*.rs` are banned; Rust unit tests live in `tests/rust/unit/<module>_tests.rs`.
- **TST-03** `src/lua_api/<module>_api.rs` holds only `impl LuaUserData`, registration, and conversions — business logic lives in `src/<module>/`.
- **TST-04** Every `mod.rs` holds only `pub mod`, `pub use`, attributes, and doc comments — definitions live in sibling files.
- **TST-05** Demo/game tests: headless Lua static-analysis tests live in `tests/lua/content/demos/test_<name>.lua` (one file per demo); binary screenshot tests live in `tests/demo_smoke_tests.rs` (`#[ignore]`). Never put demo tests in `tests/lua/unit/`.
- **TST-06** Every Lua test layer has exactly **one file per module** (`test_<module>_<layer>.lua` — e.g. `test_audio_unit.lua`, `test_audio_evidence.lua`). This rule applies to `unit/`, `evidence/`, `golden/`, `stress/`, `security/`, and `config/`. No split per-sub-feature files (e.g. `test_effect_overlay.lua` alongside `test_effect.lua`). Merge into the single module file.

## Cross-Artifact Sync

When you change one of these, you MUST update the others in the same commit.

| Changed                                      | Also update                                                              |
|----------------------------------------------|--------------------------------------------------------------------------|
| `src/<module>/*.rs`                          | `docs/specs/<module>.md`                                                 |
| `src/lua_api/<module>_api.rs`                | `docs/specs/<module>.md` · `docs/lua-api.md`                             |
| `lurek.*` API added / renamed / removed      | `content/examples/<module>.lua` · affected `content/games/` · dependent `content/library/` modules |
| New module created                           | New `docs/specs/<module>.md` · `docs/specs/README.md`                    |
| `content/library/<name>/init.lua` changed    | `content/library/<name>/example.lua` · `tests/lua/library/test_library_<name>.lua` · `tests/lua/harness.rs` · regen `docs/reports/library-docs.md` via `tools/docs/gen_lib_docs.py` |
| Contributor onboarding flow changes (build steps, first-game tutorial, quality gates) | `docs/handbook.md` (relevant section) · `CONTRIBUTING.md` if needed |
| New game demo added to `content/games/`      | `tests/lua/content/demos/test_<name>.lua` (new static-analysis test) · `tests/demo_smoke_tests.rs` (new `#[ignore]` screenshot test) · `tests/lua/harness.rs` (add `lua_demo_<name>` entry) |
| Any change                                   | `docs/CHANGELOG.md`                                                      |

Regenerate API references with `python tools/gen_all_docs.py` whenever Rust or Lua API surface changes.

## Discovery Directives

This system prompt is a discovery index, not a manual. Find specialised context on demand:

- **Skills** live in `.github/skills/<name>/SKILL.md`. Match the user's task domain to a skill's `description` frontmatter — every description is shaped "Load this skill when X. Skip it for Y." Load all that apply (a single task may need several).
- **Agents** live in `.github/agents/<name>.agent.md`. Match the task type to the `mission` frontmatter; chain via the `routes_to` field. For multi-agent work spanning ≥3 agents or ≥5 files, route to `Manager` first — Manager will engage `Planner` before any implementation begins.
- **Prompts** live in `.github/prompts/<verb>-<noun>.prompt.md`. Each is a parameterised user-selected entrypoint; the `expected_agent` frontmatter names the runner.
- **Tools** are catalogued in [`tools/README.md`](../tools/README.md) — the authoritative registry with complete script reference, dependency map, and usage guide. Each subfolder has its own `README.md` with per-script tables.
- **Module specs** live in `docs/specs/<module>.md` — load directly when you need the canonical reference for a Rust module, its Lua bindings, types, and functions.
- **Sessions** must create `work/<session-name>/` with subfolders `scripts/`, `handovers/`, `reports/`, `data/`, `examples/`, `other/`, `temp/`, `logs/`. Append one JSONL entry per completed phase to `logs/agent_log.jsonl`; never overwrite. Move completed sessions to `work/archive/`.
- **API namespace** is `lurek.*` exclusively — never bare globals or external prefixes. The Thin Wrapper Rule binds: `src/lua_api/<module>_api.rs` owns ALL `impl LuaUserData` and `mlua` imports; domain modules under `src/<module>/` stay pure-Rust.
- **Lua-first testing rule (TST-01)**: behaviour observable through `lurek.*` MUST be tested in Lua under `tests/lua/`. Rust unit tests under `tests/rust/unit/` are reserved for non-Lua-reachable internals. Full text: [philosophy.md § Testing Constraints](../docs/architecture/philosophy.md#testing-constraints).

**Full CAG system documentation:** [docs/architecture/cag-system.md](../docs/architecture/cag-system.md).

## Quality Gates

Minimum before any commit:

- Rust: `cargo test && cargo clippy -- -D warnings`.
- CAG layer: `python tools/validate/cag_validate.py` (use `--baseline` to gate against regressions).
- Docs coverage: `python tools/audit/doc_coverage.py` and `python tools/audit/test_coverage.py`.
- Generated API references: `python tools/gen_all_docs.py` after any public-API change.
- `docs/CHANGELOG.md`: every commit adds or extends an entry under the current version. Versioning is MAJOR.MINOR.PATCH per the CHANGELOG header; bumping MAJOR or MINOR also updates `Cargo.toml`.
- Confirm branch with `git rev-parse --abbrev-ref HEAD` and stage only files you changed — never `git add .`.
- Commit format: `type(scope): description` where `type` ∈ {`feat`, `fix`, `refactor`, `test`, `docs`, `chore`}. One logical change per commit.

## Repository Layout

```
src/         Rust engine source (Foundations · Core Runtime · Platform Services · Feature Systems · Edge/Integration)
tests/       Rust + Lua test suites — tests/rust/{unit,golden,ext,fixtures} and tests/lua/
docs/        Architecture, module specs, generated API references, CHANGELOG
tools/       Permanent CLI scripts — validate/, audit/, fix/, docs/, dev/, demos/, dist/, github/, assets/
content/     Lua content — games/, examples/, library/, layouts/, plugins/
.github/     CAG layer — copilot-instructions.md, agents/, skills/, prompts/
extensions/  First-party VS Code extension (extensions/vscode/)
work/        Active session folders and work/archive/
assets/      Engine assets: splash, window icon, embedded fonts
```
