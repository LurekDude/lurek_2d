---
description: "Always load. Core identity, binding constraints, cross-artifact sync rules, quality gates, and repo layout for Lurek2D."
alwaysApply: true
---

# Lurek2D System Prompt

## Communication
- Use simple English.
- No slang, idioms, or metaphors.
- Be direct and literal when following clear instructions.
- When instructions are ambiguous, ask clarifying questions instead of guessing.
- **Always complete user requests. Responsiveness > token cost.** User frustration is more expensive than extra tokens.
- When implementing features or fixes, always validate with tools before returning. Run tests, compile, check files. Don't guess.
- Define jargon when needed.
- Respond in Polish if user writes in Polish.

## Engine Identity
- Lurek2D is a single-binary 2D Rust runtime for Lua game scripts.
- Core stack: Rust stable 1.78+, LuaJIT via mlua 0.9, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9.
- License: MIT.

## Binding Constraints
- T-01 Architecture: Five module groups (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration).
- T-02 No cycles, ever. The composition root is one-way.
- A-01 Runtime only. No embedded editor or IDE. The VS Code extension is an opt-in developer experience layer, not part of the engine binary.
- A-02 Desktop only. No mobile. No WASM.
- A-03 2D graphics only. Raycasting and isometric still use 2D draw calls. No 3D scene graph or perspective projection pipeline.
- A-04 No platform SDKs like Steam or Epic in the core binary.
- B-01 LuaJIT is the main runtime. lua54 is a non-shipping fallback for testing CI where LuaJIT is unavailable.
- B-02 wgpu 22 is the only renderer backend. No OpenGL path.
- B-03 Target 60 FPS at 1080p on integrated GPUs.
- B-04 Use Rust threads for concurrency. LuaJIT VMs do not share state. Use typed MPMC Channel for cross-VM communication.
- B-05 Use TOML for human config. Use JSON only for external interop. No YAML.
- C-01 Use lurek.* only. No bare globals, no engine-prefixed names, no alternative top-level tables.
- TST-01 Behavior reachable through lurek.* must be tested in tests/lua/. Rust tests must not duplicate Lua-reachable coverage.
- TST-02 Do not put #[cfg(test)] blocks in src/**/*.rs. Rust unit tests for private code go in tests/rust/unit/<module>_tests.rs.
- TST-03 src/lua_api/<module>_api.rs holds only LuaUserData impls, registration, and type conversions. Business logic stays in src/<module>/ as pure Rust.
- TST-04 Every mod.rs holds only pub mod, pub use, attributes, and doc comments. Definitions stay in sibling files.
- TST-05 Demo tests go in tests/lua/content/games/test_<name>.lua. Screenshot demo tests go in tests/demo_smoke_tests.rs with #[ignore]. Do not put demo tests in tests/lua/unit/.
- TST-06 Each Lua test layer has one file per module: test_<module>_<layer>.lua. Do not split one module into many layer files.
- **Never edit docs/api/lurek.lua** — it's auto-generated. Always fix API doc issues at source (`src/lua_api/*_api.rs`), then regenerate using `python tools/docs/gen_lua_api_data.py` and `python tools/docs/gen_luadoc.py`.
- **Never add warning suppressions** to .vscode/settings.json to hide problems.

## Cross-Artifact Sync
- Change src/<module>/*.rs → update docs/specs/<module>.md in the same commit.
- Change src/lua_api/<module>_api.rs → update docs/specs/<module>.md; docs/api/lurek.md and docs/api/lurek.lua are generated outputs, so regenerate them from source docstrings with python tools/gen_all_docs.py.
- Add, rename, or remove lurek.* API → update content/examples/<module>.lua, affected content/games/, and dependent library modules.
- Create a new module → add docs/specs/<module>.md and update docs/specs/README.md.
- Change library/<name>/init.lua → update library/<name>/example.lua, tests/lua/library/test_library_<name>.lua, tests/lua/harness.rs, and regenerate docs/api/library.md with python tools/docs/gen_lib_docs.py.
- Change onboarding flow, build steps, tutorial, or quality gates → update docs/handbook.md and CONTRIBUTING.md if needed.
- Add a new demo in content/games/ → update tests/lua/content/games/test_<name>.lua, tests/demo_smoke_tests.rs, and tests/lua/harness.rs with lua_demo_<name>.
- Any change → update docs/CHANGELOG.md.

## Discovery Directives

**Architecture & CAG Source of Truth:**
- docs/architecture/philosophy.md - Full design assumptions (5 module groups, no cycles) and binding constraints.
- docs/architecture/cag-system.md - CAG architecture, file types, and validator contract.
- .github/agents/README.md - Cross-agent routing, ownership, and handoff contract.

**Agent System:**
- Skills live in .agents/rules/<name>.md. Match the task to the description field. Load all relevant skills.
- Agents are context personas loaded via skills. Prefer the smallest valid set.
- Workflows live in .agents/workflows/<verb>-<noun>.md. Triggered by slash commands or direct request.
- Single-agent mode: Complete requests directly without multi-agent routing.

Session workflow:
- Use the standard work/<session-name>/ layout from docs/architecture/cag-system.md.
- No agent is read-only. Agents may write plans, briefs, repros, reports, scripts, and logs under work/{session}/; scope limits product-source ownership, not session artifacts.
- Append one JSONL line per phase to logs/agent_log.jsonl.
- Move finished sessions to work/archive/.

Key references:
- docs/architecture/test-framework.md - Test placement rules and the Lua-vs-Rust decision tree.
- docs/architecture/togaf.md - TOGAF terminology, source limits, and comparison cues for enterprise-architecture work.
- docs/specs/README.md - Module-spec catalog and where to add or rename specs.
- tools/README.md - Tool inventory plus generator, validator, and audit entry points.
- docs/handbook.md - Contributor workflow, setup, and repo-wide quality expectations.

## Quality Gates
- Before any commit run cargo test and cargo clippy -- -D warnings.
- For CAG files run python tools/validate/cag_validate.py. Use --baseline if needed.
- Run python tools/audit/cag_link_check.py --strict when CAG links or file moves are touched.
- For coverage run python tools/audit/doc_coverage.py and python tools/audit/test_coverage.py.

Commit hygiene:
- Every commit must add or extend the current version entry in docs/CHANGELOG.md.
- If MAJOR or MINOR changes, update Cargo.toml too.
- Before any state-changing git action in a session, ask whether the user wants git work in that session.
- Confirm the branch with git rev-parse --abbrev-ref HEAD.
- Read-only git inspection like status, diff, log, and blame is allowed when needed.
- If git is enabled for the session, stage only touched files. Never use git add .
- Commit format is type(scope): description.
- Allowed types: feat, fix, refactor, test, docs, chore.
- Keep one logical change per commit.

## Repository Layout
- Key roots: src/, tests/, docs/, content/, tools/, .github/, work/.
- docs/ holds specs, architecture, API docs, and contributor docs. .github/ holds the legacy CAG layer. tools/ holds generators, validators, and audits.
