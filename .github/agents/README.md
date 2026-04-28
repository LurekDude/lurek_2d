# Lurek2D Agent Layer

This README is the canonical layer-level map for all Lurek2D agents. Shared contracts live here. Individual `*.agent.md` files carry specialist workflow only.

For the full agent contract, validator rules, and CAG architecture, see [docs/architecture/cag-system.md](../../docs/architecture/cag-system.md).

## Session Work-Folder Layout

Every multi-phase session creates `work/<session-name>/` with these subfolders:

`scripts/` `handovers/` `reports/` `data/` `examples/` `other/` `temp/` `logs/`

Append one JSONL entry per completed phase to `work/<session-name>/logs/agent_log.jsonl`. Never overwrite. Move completed sessions to `work/archive/`.

## Overview

Lurek2D has 20 specialist agents. Each agent owns one distinct responsibility slice. The agent layer is optimized for low token consumption, so every role should stay narrow, use simple language, and return only the evidence needed for the next step.

Manager is the only routing hub. Specialists do not dispatch work to peers. They finish their own scope and return to Manager with one of three outcomes: complete, blocked, or scope mismatch.

## Agent Directory

| Agent | Main Job | Open When |
| -------------- | ------------------------------------------- | ------------------------------------------------- |
| `Manager` | Route work, verify gates, control handoffs | Task spans multiple agents, files, or unclear ownership |
| `Planner` | Build a short phase graph | Task is large, unclear, or should be decomposed before execution |
| `Research` | Gather cited facts from repo or web | Facts are missing before a decision or implementation |
| `Solver` | Compare options and recommend one path | Facts exist but the best solution is still unclear |
| `Debugger` | Diagnose runtime failures | Crash, panic, or wrong runtime behavior needs root cause |
| `Architect` | Define module boundaries and migration steps | Ownership, layering, or dependency direction is the issue |
| `Developer` | Implement non-specialist Rust | Work is real code but outside render, physics, audio, config, docs, and CAG |
| `Lua-Designer` | Design `lurek.*` API shape | Public Lua naming, signatures, defaults, or callbacks must change |
| `Renderer` | Implement render subsystem work | wgpu, RenderCommand, shaders, textures, or render bindings are in scope |
| `Physicist` | Implement physics subsystem work | bodies, shapes, joints, queries, or contact flow are in scope |
| `Audio-Eng` | Implement audio subsystem work | decode, mixer, playback, streaming, or audio bindings are in scope |
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
| Evidence and Decisions | `Research`, `Solver`, `Debugger`, `Architect` | gather facts, explain runtime causes, choose paths, define structure |
| Delivery | `Developer`, `Lua-Designer`, `Renderer`, `Physicist`, `Audio-Eng`, `Configurator`, `Doc-Writer`, `CAG-Architect` | design or implement a bounded artifact class |
| Assurance | `Tester`, `Reviewer`, `Optimizer`, `Security` | prove behavior, gate diffs, measure cost, audit risk |
| Experience | `Hacker`, `Player` | probe hostile behavior and review subjective friction |

## Routing Contract

- Only `Manager` routes between agents.
- Every specialist returns to `Manager` with a completion packet, blocker packet, or scope-mismatch packet.
- Prefer one agent when one agent is enough.
- Route to `Planner` before implementation when work spans 3 or more agents or 5 or more files.
- Keep handoffs short: goal, touched files, gate, and only the evidence the next agent needs.

## Ownership Graph

- `Research` answers questions with citations. `Solver` uses known facts to choose a path.
- `Debugger` explains runtime failure causes. `Tester` turns known behavior into tests.
- `Architect` changes module ownership. `Developer` implements inside accepted ownership.
- `Lua-Designer` defines public Lua shape. `Developer`, `Renderer`, `Physicist`, or `Audio-Eng` implement the accepted shape.
- `Reviewer` judges finished diffs. `Player` judges feel. `Security` audits static risk. `Hacker` creates hostile runtime evidence.
- `Optimizer` measures cost. It does not implement fixes.
- `Doc-Writer` explains verified behavior. `Configurator` owns game config templates. `CAG-Architect` owns `.github` guidance and validators.

## Fast Routing Heuristics

- Multi-step work, unclear ownership, or cross-cutting change: `Manager`
- Facts missing: `Research`
- Best fix still unclear after facts: `Solver`
- Runtime bug or crash: `Debugger`
- Module boundary or dependency issue: `Architect`
- New or changed `lurek.*` API: `Lua-Designer`
- Non-specialist Rust implementation: `Developer`
- Render subsystem: `Renderer`
- Physics subsystem: `Physicist`
- Audio subsystem: `Audio-Eng`
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
