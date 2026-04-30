# Lurek2D Agent Layer

This README is the canonical layer-level map for all Lurek2D agents. Shared contracts live here. Individual `*.agent.md` files carry specialist workflow only.

For the full agent contract, validator rules, and CAG architecture, see [docs/architecture/cag-system.md](../../docs/architecture/cag-system.md).

## Session Work-Folder Layout

Every multi-phase session creates `work/<session-name>/` with these subfolders:

`scripts/`: repros, probes, helper scripts, and generated test inputs.
`handovers/`: phase plans, routing packets, and acceptance-gate notes.
`reports/`: research briefs, audits, review verdicts, decision memos, and performance reports.
`data/`: queries, extracted datasets, metrics tables, and notebook outputs.
`examples/`: minimal runnable repros or sample slices created during the session.
`other/`: small artifacts that do not fit another bucket.
`temp/`: disposable intermediate files.
`logs/`: `agent_log.jsonl` and captured command notes.

Append one JSONL entry per completed phase to `work/<session-name>/logs/agent_log.jsonl`. Never overwrite. Move completed sessions to `work/archive/`.

## Overview

Lurek2D has 27 specialist agents. Each agent owns one distinct product-work slice. The agent layer is optimized for low token consumption, so every role should stay narrow, use simple language, and return only the evidence needed for the next step.

No CAG agent is read-only. Any agent may create or update `work/{session}/` artifacts; scope limits product-source ownership, not plans, briefs, repros, reports, scripts, or logs.

Agents share one autonomy rule from the system prompt: they work until done, blocked, or out of scope, then return to Manager. Each agent closes by scoring its result against its own Success Metrics.

Manager is the only routing hub. Specialists do not dispatch work to peers. They finish their own scope and return to Manager with one of three outcomes: complete, blocked, or scope mismatch.
Manager loads [agent-routing](../skills/agent-routing/SKILL.md) whenever ownership, routing, or handoff shape is part of the task.

## Agent Directory

| Agent | Main Job | Open When |
| -------------- | ------------------------------------------- | ------------------------------------------------- |
| `Manager` | Orchestrate subagents, gates, and handoffs | Task spans multiple agents, files, or unclear ownership |
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
| `Doc-Writer` | Update markdown docs and generated references | verified behavior must be explained in docs or generated references refreshed |
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
- `Manager` must load [agent-routing](../skills/agent-routing/SKILL.md) before choosing owners, phases, or handoff shape.
- Every specialist returns to `Manager` with a completion packet, blocker packet, or scope-mismatch packet.
- Prefer one agent when one agent is enough.
- Keep handoffs short: goal, touched files, gate, and only the evidence the next agent needs.

Exact ownership heuristics, role boundaries, and phase-routing thresholds live in [agent-routing](../skills/agent-routing/SKILL.md) so they stay in one maintained place.
The docs boundary is: `Spec-Owner` owns `docs/specs/`; `Doc-Writer` owns other markdown docs and generated references.

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
- Write plans, briefs, repros, scripts, and reports to `work/{session}/` when the session uses artifacts.
- Follow the shared system-prompt autonomy rule instead of repeating it in each file.
- End by scoring the result against the role's Success Metrics on a 1 to 10 star scale.
- If a task exceeds the agent's scope, escalate instead of absorbing it.

## Agent Authoring Standard

- Keep each agent file short and role-specific.
- Required sections: `Mission`, `Scope`, `Inputs`, `Outputs`, `Workflow`, `Success Metrics`, `Anti-patterns`, `CAG Metadata`.
- `Scope` contains owned work only. Do not duplicate ownership rules through a `Must Not Become` list.
- `Scope` and `Anti-patterns` should be specific enough to distinguish the role from its nearest neighbors.
- `Workflow` should be concrete, low-token, and unique to the agent.
- Keep routing specifics in shared docs or [agent-routing](../skills/agent-routing/SKILL.md), not in per-agent sections.
- Do not describe agents as read-only. If an agent stops before product implementation, say what it still writes.
- The autonomy rule belongs in the system prompt, not in agent files.
- `Success Metrics` uses 3 to 6 role-specific bullets and explains the 1 to 10 star self-evaluation scale.
- `CAG Metadata` uses plain text lines for communication style, personas, primary skills, and secondary skills.
- Shared policy belongs in this README or the system prompt, not repeated across every agent file.
