# CAG Agents Roster (v2)

Consolidated from 27 agents to 12. Previous agents merged into broader roles that cover overlapping workflow modes.

## Merge map

| Previous agents | New agent |
|---|---|
| Manager | Manager |
| Planner, Research, Analyst, Discovery-Lead | Planner |
| Architect, Solver | Architect |
| Developer, Renderer, Physicist, Audio-Eng, Debugger | Developer |
| Lua-Designer | Lua-Designer |
| Content-Maker, Player, Configurator | Content-Maker |
| Extension-Engineer | Extension-Engineer |
| Build-Engineer | Build-Engineer |
| Tester, Hacker, Security (test part) | Tester |
| Reviewer, Optimizer, Security (review part) | Verifier |
| Doc-Writer, Spec-Owner | Doc-Writer |
| CAG-Architect, RAG-Architect | CAG-Architect |

## Routing contract

- **Single-agent mode**: Routing is ignored. Tasks completed directly by the assigned agent.
- **Multi-agent mode**: Only `Manager` routes. Specialists never route to peers.
- `Manager` orchestrates, gates, and closes. Does not implement.
- `Planner` is required before implementation when scope is unclear or multi-phase.
- `Architect` owns high-level design and acts as solver for hard problems. Does not implement.
- `Verifier` reviews finished work. Does not write tests or fix code.
- `Tester` writes test cases and adversarial probes. Does not fix production code.

## Agent scope summary

| Agent | Core responsibility |
|---|---|
| Manager | Route, gate, close. No implementation. |
| Planner | Plans, research, analytics, opportunity discovery. Answers: what to do and in what order. |
| Architect | Architecture docs, module boundaries, design decisions, solver flow. Answers: is the solution coherent with the system. |
| Developer | All Rust engine code: runtime, renderer, physics, audio, assets, debugging. |
| Lua-Designer | lurek.* API surface as a product. src/lua_api/, docstrings, generators. |
| Content-Maker | content/examples/, content/games/, library/, conf files, player-review feedback. |
| Extension-Engineer | extensions/vscode/ commands, panels, language features, generated data sync. |
| Build-Engineer | Cargo profiles, build tasks, CI, packaging, dist scripts. |
| Tester | Lua-first tests, Rust unit tests, adversarial probes, security test cases. |
| Verifier | Final quality gate: code review, architecture review, security review, performance gate, accept/reject. |
| Doc-Writer | All docs, specs, wiki, handbook, changelog. Detects and fixes spec drift. |
| CAG-Architect | .github CAG layer, validators, agent graph, retrieval corpus. |

## Skill bundles

| Agent | Primary skills | Secondary skills |
|---|---|---|
| Manager | agent-routing, quality-pipeline | module-architecture, roadmap-planning, solution-options, tools-cag-validation |
| Planner | roadmap-planning, opportunity-discovery, analytics | github-workflow, documentation, enterprise-architecture |
| Architect | module-architecture, enterprise-architecture, solution-options | documentation, agent-md, togaf, roadmap-planning, rust-coding |
| Developer | rust-coding, error-handling, dev-debugging | module-architecture, gpu-programming, performance-profiling, lua-rust-bridge, asset-pipeline |
| Lua-Designer | lua-api-design, lua-scripting, lua-rust-bridge | documentation, lua-runtime, threading |
| Content-Maker | lua-scripting, examples-management, library-authoring, demo-creation | documentation, game-ai, ui-layout, html-css, lua-api-design |
| Extension-Engineer | vscode-extension | documentation, html-css, ui-layout, build-system, lua-api-design |
| Build-Engineer | build-system, ci-cd-pipeline, quality-pipeline | cross-platform, github-workflow, tools-cag-validation, documentation |
| Tester | testing-rust, error-handling, lua-scripting | rust-coding, lua-rust-bridge, module-architecture, dev-debugging, lua-runtime |
| Verifier | module-audit, performance-profiling | testing-rust, error-handling, quality-pipeline, dev-debugging, rust-coding |
| Doc-Writer | documentation, agent-md | lua-api-design, roadmap-planning, enterprise-architecture, github-workflow, module-architecture |
| CAG-Architect | cag-workflow, tools-cag-validation, agent-routing | retrieval-architecture, documentation, module-architecture, enterprise-architecture |
