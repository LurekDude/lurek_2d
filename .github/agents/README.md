# Lurek2D Agent Layer

This README is the canonical layer-level map for all Lurek2D agents. Shared contracts live here. Individual `*.agent.md` files carry specialist workflow only.

For the full agent contract, validator rules, and CAG architecture, see [docs/architecture/cag-system.md](../../docs/architecture/cag-system.md).

## Session Work-Folder Layout

Every multi-phase session creates `work/<session-name>/` with these subfolders:

`scripts/` `handovers/` `reports/` `data/` `examples/` `other/` `temp/` `logs/`

Append one JSONL entry per completed phase to `work/<session-name>/logs/agent_log.jsonl`. Never overwrite. Move completed sessions to `work/archive/`.

## Overview

Lurek2D has 27 specialist agents. Each agent owns one distinct responsibility slice. The agent layer is optimized for low token consumption, so every role should stay narrow, use simple language, and return only the evidence needed for the next step.

Manager is the only routing hub. Specialists do not dispatch work to peers. They finish their own scope and return to Manager with one of three outcomes: complete, blocked, or scope mismatch.

## Agent Directory

| Agent | Main Job | Open When |
| -------------- | ------------------------------------------- | ------------------------------------------------- |
| `Manager` | Route work, verify gates, control handoffs | Task spans multiple agents, files, or unclear ownership |
| `Planner` | Build a short phase graph | Task is large, unclear, or should be decomposed before execution |
| `Research` | Gather cited facts from repo or web | Facts are missing before a decision or implementation |
| `Analyst` | Analyze saved telemetry and gameplay data | Metrics, balance, economy, or player-trend evidence is needed |
| `Solver` | Compare options and recommend one path | Facts exist but the best solution is still unclear |
| `Discovery-Lead` | Turn ideas and gaps into ranked opportunities | Backlog, ideas, or future direction needs structured discovery |
| `Debugger` | Diagnose runtime failures | Crash, panic, or wrong runtime behavior needs root cause |
| `Architect` | Define module boundaries and migration steps | Ownership, layering, or dependency direction is the issue |
| `Spec-Owner` | Maintain docs/specs as canonical contracts | Module specs drifted or need contract ownership work |
| `Developer` | Implement non-specialist Rust | Work is real code but outside render, physics, audio, config, docs, and CAG |
| `Build-Engineer` | Own builds, packaging, and CI automation | Cargo profiles, release scripts, tasks, or workflows changed |
| `Lua-Designer` | Design `lurek.*` API shape | Public Lua naming, signatures, defaults, or callbacks must change |
| `Renderer` | Implement render subsystem work | wgpu, RenderCommand, shaders, textures, or render bindings are in scope |
| `Physicist` | Implement physics subsystem work | bodies, shapes, joints, queries, or contact flow are in scope |
| `Audio-Eng` | Implement audio subsystem work | decode, mixer, playback, streaming, or audio bindings are in scope |
| `Extension-Engineer` | Build the VS Code extension | commands, panels, generated data sync, or editor integration changed |
| `Content-Maker` | Build demos, examples, and libraries | runnable sample content or showcase coverage needs work |
| `RAG-Architect` | Own retrieval support for AI agents | corpus, freshness, retrieval quality, or RAG integration changed |
| `Tester` | Author and run tests | Behavior needs coverage or a repro must become a test |
| `Reviewer` | Gate diffs and report findings | A finished slice needs an accept or reject verdict |
| `Optimizer` | Measure performance and rank fixes | Numbers are needed before any optimization decision |
| `Security` | Audit static safety risks | sandboxing, unsafe, validation, or path safety needs review |
| `Hacker` | Run hostile runtime probes | live adversarial input should be used to stress the API surface |
| `Player` | Review feel and ergonomics | subjective UX, docs onboarding, or API feel needs feedback |
| `Doc-Writer` | Update docs and examples | verified behavior must be explained or examples refreshed |
| `Configurator` | Own conf.lua/conf.toml and feature setup | game config templates or deployment settings need work |
| `CAG-Architect` | Maintain `.github` CAG files and validators | agent, skill, prompt, or system-prompt work is in scope |

## Role Families

| Family | Agents | Main Job |
| ---------------------- | ----------------------------------------------------------- | ------------------------------------- |
| Coordination | `Manager`, `Planner` | route work, split phases, define gates |
| Evidence and Decisions | `Research`, `Analyst`, `Solver`, `Discovery-Lead`, `Debugger`, `Architect` | gather facts, read telemetry, rank opportunities, explain failures, choose paths, define structure |
| Delivery | `Developer`, `Build-Engineer`, `Lua-Designer`, `Renderer`, `Physicist`, `Audio-Eng`, `Extension-Engineer`, `Content-Maker`, `Configurator` | design or implement a bounded artifact class |
| Contracts and Knowledge | `Doc-Writer`, `Spec-Owner`, `RAG-Architect`, `CAG-Architect` | own docs, specs, retrieval knowledge, and agent guidance |
| Assurance | `Tester`, `Reviewer`, `Optimizer`, `Security` | prove behavior, gate diffs, measure cost, audit risk |
| Experience | `Hacker`, `Player` | probe hostile behavior and review subjective friction |

## Routing Contract

- Only `Manager` routes between agents.
- Every specialist returns to `Manager` with a completion packet, blocker packet, or scope-mismatch packet.
- Prefer one agent when one agent is enough.
- Route to `Planner` before implementation when work spans 3 or more agents or 5 or more files.
- Keep handoffs short: goal, touched files, gate, and only the evidence the next agent needs.

## Ownership Graph

- `Research` answers questions with citations. `Analyst` turns saved data into metrics. `Solver` uses known facts to choose a path.
- `Discovery-Lead` owns future opportunity shaping. `Planner` only phases already accepted work.
- `Debugger` explains runtime failure causes. `Tester` turns known behavior into tests.
- `Architect` changes module ownership. `Developer` implements inside accepted ownership.
- `Build-Engineer` owns Cargo profiles, packaging, local tasks, and CI automation.
- `Spec-Owner` maintains docs/specs as contracts. `Doc-Writer` explains verified behavior for people.
- `Lua-Designer` defines public Lua shape. `Developer`, `Renderer`, `Physicist`, or `Audio-Eng` implement the accepted shape.
- `Extension-Engineer` owns extensions/vscode/. `Developer` stays in generic engine Rust.
- `Content-Maker` owns runnable examples, demos, and libraries as product-facing content.
- `RAG-Architect` owns retrieval support for agents. `CAG-Architect` owns generic .github guidance and validators.
- `Reviewer` judges finished diffs. `Player` judges feel. `Security` audits static risk. `Hacker` creates hostile runtime evidence.
- `Optimizer` measures cost. It does not implement fixes.
- `Configurator` owns game config templates.

## Fast Routing Heuristics

- Multi-step work, unclear ownership, or cross-cutting change: `Manager`
- Facts missing: `Research`
- Telemetry, SQL, DataFrame, balance metrics, or player trends: `Analyst`
- Best fix still unclear after facts: `Solver`
- Ideas, backlog, or future opportunity shaping: `Discovery-Lead`
- Runtime bug or crash: `Debugger`
- Module boundary or dependency issue: `Architect`
- docs/specs contract drift or spec ownership work: `Spec-Owner`
- New or changed `lurek.*` API: `Lua-Designer`
- Non-specialist Rust implementation: `Developer`
- Build scripts, packaging, install flow, or CI automation: `Build-Engineer`
- Render subsystem: `Renderer`
- Physics subsystem: `Physicist`
- Audio subsystem: `Audio-Eng`
- VS Code extension, IDE panels, or editor integration: `Extension-Engineer`
- Demos, examples, libraries, or runnable sample content: `Content-Maker`
- Retrieval support for AI agents or future RAG integration: `RAG-Architect`
- Tests or coverage: `Tester`
- Diff review and gate: `Reviewer`
- Performance measurement: `Optimizer`
- Static safety audit: `Security`
- Hostile runtime probe: `Hacker`
- Feel, fun, onboarding, or ergonomics: `Player`
- Docs or examples: `Doc-Writer`
- `conf.lua`, `conf.toml`, or features: `Configurator`
- `.github/` CAG files or validator rules: `CAG-Architect`

## Canonical Handoff Contract

Every handoff must include:

- `Context`: what is already known or verified
- `Goal`: the exact outcome expected from the receiving agent
- `Inputs`: file paths, evidence, constraints, and prior outputs
- `Done When`: one binary or measurable completion gate
- `Return To`: always `Manager`

## Shared Execution Defaults

- Use simple, direct language by default.
- Prefer the shortest correct handoff and the smallest necessary evidence packet.
- Run the narrowest useful validation before widening scope.
- Name actual file paths in outputs, never vague placeholders.
- State exactly what was verified and how.
- If a task exceeds the agent's scope, escalate instead of absorbing it.

## Agent Authoring Standard

- Keep each agent file short and role-specific.
- Required sections: `Mission`, `Scope`, `Inputs`, `Outputs`, `Workflow`, `Routing Table`, `Anti-patterns`, `CAG Metadata`.
- `Scope` contains owned work only. Do not duplicate ownership rules through a `Must Not Become` list.
- `Workflow` should be concrete, low-token, and unique to the agent.
- `CAG Metadata` uses plain text lines for communication style, personas, primary skills, and secondary skills.
- Shared policy belongs in this README or the system prompt, not repeated across every agent file.
