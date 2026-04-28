# Lurek2D System Prompt

## Communication
- Use simple English.
- No slang, idioms, or metaphors.
- Be direct and literal.
- Prefer the shortest correct answer and the shortest sufficient handoff.
- Optimize for minimum token use. GitHub Copilot is on a consumption-based model.
- Default to simple communication. Use creative wording only when the active agent role requires it.
- Define jargon when needed.
- After each compaction, reload this prompt, reload the active agent file, and check needed skills again.

## Engine Identity
- Lurek2D is a 2D Rust engine that runs Lua game scripts with LuaJIT through mlua 0.9.
- lua54 is a fallback only. It is not for shipping builds.
- Tech baseline: Rust stable 1.78+, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9.
- Public API namespace is lurek.* only.
- Desktop only: Windows, Linux, macOS, x86_64, ARM.
- MIT license.
- Single binary.
- No embedded editor.

## Binding Constraints
- A-01 Runtime only. No embedded editor or IDE.
- A-02 Desktop only. No mobile. No WASM.
- A-03 2D graphics only. Raycasting and isometric still use 2D draw calls.
- A-04 No platform SDKs like Steam or Epic in the core binary.
- B-01 LuaJIT is the main runtime. lua54 is a non-shipping fallback.
- B-02 wgpu 22 is the only renderer backend. No OpenGL path.
- B-03 Target 60 FPS at 1080p on integrated GPUs.
- B-04 Use Rust threads for concurrency. LuaJIT VMs do not share state. Use Channel for cross-VM communication.
- B-05 Use TOML for human config. Use JSON only for external interop. No YAML.
- TST-01 Behavior reachable through lurek.* must be tested in tests/lua/.
- TST-02 Do not put #[cfg(test)] blocks in src/**/*.rs. Rust unit tests go in tests/rust/unit/<module>_tests.rs.
- TST-03 src/lua_api/<module>_api.rs holds only LuaUserData impls, registration, and conversions. Business logic stays in src/<module>/.
- TST-04 Every mod.rs holds only pub mod, pub use, attributes, and doc comments. Definitions stay in sibling files.
- TST-05 Demo tests go in tests/lua/content/games/test_<name>.lua. Screenshot demo tests go in tests/demo_smoke_tests.rs with #[ignore]. Do not put demo tests in tests/lua/unit/.
- TST-06 Each Lua test layer has one file per module: test_<module>_<layer>.lua. Do not split one module into many layer files.

## Cross-Artifact Sync
- Change src/<module>/*.rs -> update docs/specs/<module>.md in the same commit.
- Change src/lua_api/<module>_api.rs -> update docs/specs/<module>.md and docs/api/lurek.md.
- Add, rename, or remove lurek.* API -> update content/examples/<module>.lua, affected content/games/, and dependent library modules.
- Create a new module -> add docs/specs/<module>.md and update docs/specs/README.md.
- Change library/<name>/init.lua -> update library/<name>/example.lua, tests/lua/library/test_library_<name>.lua, tests/lua/harness.rs, and regenerate docs/api/library.md with python tools/docs/gen_lib_docs.py.
- Change onboarding flow, build steps, tutorial, or quality gates -> update docs/handbook.md and CONTRIBUTING.md if needed.
- Add a new demo in content/games/ -> update tests/lua/content/games/test_<name>.lua, tests/demo_smoke_tests.rs, and tests/lua/harness.rs with lua_demo_<name>.
- Any change -> update docs/CHANGELOG.md.
- After any Rust or Lua API change, run python tools/gen_all_docs.py.

## Discovery Directives
- This file is an index, not a manual. Load more context only when needed.
- Skills live in .github/skills/<name>/SKILL.md. Match the task to the description field. The description must say when to load and when to skip. Load all relevant skills.
- Agents live in .github/agents/<name>.agent.md. Match the task to the mission field and route with routes_to.
- Agents must have distinct scope. Prefer the smallest valid agent set.
- Agents are self-contained specialists. They complete their own scope and return to Manager.
- Only Manager routes between agents.
- If work spans 3 or more agents or 5 or more files, route to Manager first. Manager routes to Planner before implementation.
- Prompts live in .github/prompts/<verb>-<noun>.prompt.md. expected_agent names the runner.
- Tools are listed in tools/README.md.

- Module specs live in docs/specs/<module>.md.
- Use the standard work/<session-name>/ layout from docs/architecture/cag-system.md.
- Append one JSONL line per phase to logs/agent_log.jsonl.
- Move finished sessions to work/archive/.

- Use lurek.* only. Never use bare globals or outside prefixes.
- Thin Wrapper Rule: src/lua_api/<module>_api.rs owns all LuaUserData impls and mlua imports. Domain code stays in src/<module>/.
- Lua-first testing still applies: tests/lua/ for lurek.* behavior, tests/rust/unit/ only for Rust-only internals.
- Full CAG reference lives in docs/architecture/cag-system.md.

## Quality Gates
- Before any commit run cargo test and cargo clippy -- -D warnings.
- For CAG files run python tools/validate/cag_validate.py. Use --baseline if needed.
- For coverage run python tools/audit/doc_coverage.py and python tools/audit/test_coverage.py.

- After any public API change run python tools/gen_all_docs.py.
- Every commit must add or extend the current version entry in docs/CHANGELOG.md.
- If MAJOR or MINOR changes, update Cargo.toml too.
- Confirm the branch with git rev-parse --abbrev-ref HEAD.

- Stage only changed files. Never use git add .
- Commit format is type(scope): description.
- Allowed types: feat, fix, refactor, test, docs, chore.
- Keep one logical change per commit.

## Repository Layout
- Key roots: src/, tests/, docs/, content/, tools/, .github/, work/.
- See docs/architecture/cag-system.md and tools/README.md for full layout details.

