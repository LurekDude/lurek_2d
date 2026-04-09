# Lurek2D Agent Layer

This README is the canonical layer-level map for all Lurek2D agents. Shared contracts live here — individual `*.agent.md` files carry specialist workflow only.

## Overview

Lurek2D has 20 specialist agents. Each owns a distinct role in the game engine development workflow. This file defines shared execution defaults, the canonical handoff contract, routing heuristics, and boundary rules that apply across all agents.

## Agent Directory

| Agent          | Main Job                                    | Open When                                         |
| -------------- | ------------------------------------------- | ------------------------------------------------- |
| `Manager`      | Orchestrate multi-step workflows            | Task spans multiple agents or modules             |
| `Planner`      | Decompose complex tasks into phased plans   | Task is large, unclear, or spans 4+ phases        |
| `Research`     | Search web/docs/codebase for facts          | External knowledge needed before implementation   |
| `Solver`       | Root-cause analysis and solution selection  | Hard problem with no obvious answer               |
| `Developer`    | Implement Rust engine features              | Writing or modifying Rust source code             |
| `Lua-Designer` | Design the `lurek.*` Lua API surface         | Adding/changing Lua-facing APIs                   |
| `Renderer`     | Graphics pipeline and rendering             | Working on wgpu, DrawCommand, textures       |
| `Physicist`    | Physics engine implementation               | Collision, bodies, world step, forces             |
| `Audio-Eng`    | Audio system and rodio integration          | Sound loading, playback, mixer                    |
| `Tester`       | Write and maintain tests                    | Adding tests, fixing test failures, coverage      |
| `Reviewer`     | Code review and quality gates               | PR review, compliance check, architecture audit   |
| `Debugger`     | Runtime diagnosis and bug tracing           | Crash investigation, unexpected behavior          |
| `Optimizer`    | Performance profiling and hot-path tuning   | Frame time issues, memory usage, allocations      |
| `Architect`    | Module structure and API design             | Refactoring, new module design, dependency graph  |
| `Doc-Writer`   | Documentation and tutorials                 | API docs, README updates, example writing         |
| `Security`     | Memory safety and Lua sandboxing            | Input validation, path traversal, unsafe audit    |
| `CAG-Architect`| Maintain the CAG layer files                | Adding/editing agents, skills, prompts, instructions |
| `Configurator` | conf.lua/conf.toml templates, Cargo features| game config, feature flags, deployment setup         |
| `Hacker`       | Adversarial edge case discovery             | finding attack vectors, feeding Security and Tester  |
| `Player`       | Subjective gameplay/API experience review   | fun assessment, friction identification via personas |

## Role Families

| Family                 | Agents                                                      | Main Job                              |
| ---------------------- | ----------------------------------------------------------- | ------------------------------------- |
| Orchestration          | `Manager`, `Planner`                                        | Route tasks, define gates, build plans |
| Intelligence           | `Research`, `Solver`                                        | Gather facts, find solutions before implementation |
| Delivery               | `Developer`, `Lua-Designer`, `Renderer`, `Physicist`, `Audio-Eng` | Build features, implement systems |
| Design and Structure   | `Architect`, `Doc-Writer`, `CAG-Architect`                  | Design APIs, structure, documentation |
| Assurance              | `Tester`, `Reviewer`, `Debugger`, `Optimizer`, `Security`   | Gate, test, harden, optimize          |
| Experience             | `Hacker`, `Player`                                          | Adversarial probing, subjective quality feedback |
| Delivery (config)      | `Configurator`                                              | Game configuration templates and feature validation |

## Boundary Rules

| Agent          | Owns                                      | Must Not Become                          |
| -------------- | ----------------------------------------- | ---------------------------------------- |
| `Manager`      | Task routing, sequencing, acceptance, session start | Shadow Developer writing code   |
| `Planner`      | Phase decomposition, dependency mapping   | Shadow Manager executing handoffs        |
| `Research`     | Evidence gathering, web/codebase search   | Shadow Developer implementing solutions  |
| `Solver`       | Root cause, alternatives, recommendation  | Shadow Developer writing implementation  |
| `Developer`    | Rust implementation, bug fixes            | Shadow Architect redesigning modules     |
| `Lua-Designer` | `lurek.*` API surface, binding patterns    | Shadow Developer for engine internals    |
| `Renderer`     | Graphics pipeline, draw commands          | Shadow Physicist or Audio-Eng            |
| `Physicist`    | Physics simulation, collision             | Shadow Renderer for visual output        |
| `Audio-Eng`    | Audio pipeline, rodio integration         | Shadow Developer for non-audio code      |
| `Tester`       | Test writing, coverage, test strategy     | Shadow Developer fixing production bugs  |
| `Reviewer`     | Quality gates, compliance checks          | Shadow Developer rewriting code          |
| `Debugger`     | Diagnosis, root cause analysis            | Shadow Developer implementing fixes      |
| `Optimizer`    | Performance analysis, benchmarks          | Shadow Architect for structural redesign |
| `Architect`    | Module design, dependency rules           | Shadow Developer for implementation      |
| `Doc-Writer`   | Docs, tutorials, API reference            | Shadow Developer for code changes        |
| `Security`     | Safety audits, sandboxing review          | Shadow Developer patching vulnerabilities|
| `CAG-Architect`| CAG file maintenance, validation rules    | Shadow Developer for engine code         |
| `Configurator` | conf.lua/conf.toml templates, Cargo feature flags | Shadow Developer or Architect        |
| `Hacker`       | Adversarial probing, edge case discovery  | Shadow Developer fixing vulnerabilities (route to Security/Tester) |
| `Player`       | Subjective experience reports via personas| Shadow Lua-Designer or Doc-Writer for API changesry |

## Fast Routing Heuristics

### Route by Artifact

- Rust source file change → `Developer`
- New `lurek.*` function → `Lua-Designer` then `Developer`
- DrawCommand or Renderer change → `Renderer`
- Physics body/world/collision → `Physicist`
- Audio mixer/source → `Audio-Eng`
- Test file → `Tester`
- Code review → `Reviewer`
- Bug diagnosis → `Debugger`
- Slow frame time → `Optimizer`
- Module layout question → `Architect`
- Documentation update → `Doc-Writer`
- Security concern → `Security`
- `.github/` file edit → `CAG-Architect`
- Multi-module feature → `Manager`
- Complex multi-phase new feature → `Planner` → `Manager`
- External docs/API needed → `Research`
- Hard engineering problem → `Solver`
- conf.lua / conf.toml design → `Configurator`
- Adversarial edge case discovery → `Hacker`
- Fun / ergonomics / experience review → `Player`

### Route by Scale

- **XS/S** (single file, bounded change) → `Developer` or specialist
- **M** (one module, needs review) → specialist then `Reviewer`
- **L/XL** (multi-module, architectural) → `Manager` to orchestrate

## Canonical Handoff Contract

When routing between agents, every handoff must include:

- **Context** — what is already known, verified, or completed
- **Goal** — the exact outcome expected from the receiving agent
- **Inputs** — file paths, evidence, prior outputs, constraints
- **Done When** — binary or measurable completion gate
- **Next** — the next owner after this step

## Shared Execution Defaults

- Run `cargo test` after every code change before claiming done
- Run `cargo clippy` with 0 warnings before any handoff
- Name actual file paths in outputs — never "the relevant file"
- State what was verified and how (test output, manual check, etc.)
- If a task exceeds the agent's scope, escalate — don't absorb

## Success Metric Contract

Each agent defines 5–8 measurable success metrics in its `*.agent.md` file. These metrics must be:
- Markable as `met` / `missed` / `unknown` from the produced artifact
- Checked by `Reviewer` or `Manager` at handoff
- Specific to the role — not generic engineering advice

## Agent Authoring Standard

- Target size: 150–300 lines per agent file
- Required sections: Mission, Scope, Core Skills, Output Contract, Success Metrics, Workflow, Decision Gates, Routing, Best Practices, Anti-Patterns
- Shared wording belongs in this README — never duplicate across agent files
- Agent descriptions must include explicit non-goals
