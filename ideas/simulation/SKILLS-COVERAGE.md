# Skills Coverage Matrix

This document maps the coverage relationship between simulator mechanics,
business domains, and skill files. Use it to identify which skill to load
for a given task and to detect coverage gaps.

Last updated: 2026-04-03

---

## 1. Skills Inventory

15 skill folders under `.github/skills/`:

| # | Skill | SKILL.md Lines | Topic Files | Examples | Purpose |
|---|---|---|---|---|---|
| 1 | block-configuration-guide | 250 | 0 | 12 | Parameter decision trees, sizing heuristics, anti-patterns |
| 2 | business-process-mapping | 283 | 0 | 5 | Business domain → block model translation methodology |
| 3 | data-pipeline | 45 | 0 | 3 | DuckDB data lake structure, ELT pipeline design |
| 4 | domain-process-archetypes | 289 | 0 | 0 | Industry archetype classification (physical/virtual/approval/knowledge/hybrid) |
| 5 | duckdb-analytics | 45 | 0 | 7 | DuckDB query patterns for simulation JSONL data |
| 6 | migration-nextjs | 77 | 0 | 1 | Flask → Next.js migration plan and phases |
| 7 | react-nextjs | 39 | 0 | 4 | React + Next.js component patterns, SSE integration |
| 8 | simulator-mechanics | 85 | 13 | 91 | All 33 mechanics across 13 topic files |
| 9 | simulator-patterns | 216 | 0 | 13 | 13 reusable sub-graph patterns |
| 10 | simulator-playbook-guide | 185 | 0 | 16 | Step-by-step playbook construction |
| 11 | simulator-templates | 140 | 0 | 7 | Template system, ports, parameter overrides, instantiation |
| 12 | simulator-translation-guide | 567 | 0 | 8 | 19 domain keyword → mechanic mapping tables |
| 13 | tailwind-css | 38 | 0 | 4 | Tailwind styling conventions and design tokens |
| 14 | team-department-modeling | 256 | 0 | 25 | Person → team → department composites, worked examples |
| 15 | yaml-authoring | 80 | 0 | 2 | YAML config rules, structure validation, stable IDs |

**Totals**: 2,595 lines of skill documentation, 13 topic files, 198 example files.

---

## 2. Mechanic Coverage Matrix

All 33 mechanics from `docs/BLOCK-DESIGN.md` §12 mapped to skill file coverage.

| # | Mechanic | Primary Skill (topic file) | Also Referenced In |
|---|---|---|---|
| 13.1 | Skill requirement on data | simulator-mechanics/07-resources | translation-guide §1 Workforce, team-department-modeling |
| 13.2 | Machine / resource state | simulator-mechanics/04-reliability | config-guide (fail_chance, circuit_breaker), translation-guide §2 Equipment |
| 13.3 | Time-based scheduling | simulator-mechanics/08-scheduling | config-guide (processing_ticks), playbook-guide §2, translation-guide §1 |
| 13.4 | Conditional event routing | simulator-mechanics/05-signals-events | patterns #6 Incident Pipeline |
| 13.5 | Value formula | simulator-mechanics/06-value-economics | config-guide (Value Economics Cheat Sheet) |
| 13.6 | Data conversion inside block | simulator-mechanics/09-data-routing | translation-guide §3 Logistics |
| 13.7 | Conditional branching (router) | simulator-mechanics/09-data-routing | config-guide (Router Operator Reference), patterns #8 Parallel Processing |
| 13.8 | Accumulator / counter | simulator-mechanics/01-node-types | config-guide (Accumulator), patterns #3 Supply Chain |
| 13.9 | Priority queue | simulator-mechanics/02-container | translation-guide §7 IT Operations |
| 13.10 | Data enrichment (join) | simulator-mechanics/01-node-types | patterns #8 Parallel Processing |
| 13.11 | Item aging & priority escalation | simulator-mechanics/02-container | translation-guide §10 Healthcare |
| 13.12 | Shared resource pool | simulator-mechanics/07-resources | config-guide (resource pools), team-department-modeling §7 |
| 13.13 | Backpressure propagation | simulator-mechanics/02-container | playbook-guide §5 |
| 13.14 | Circuit breaker | simulator-mechanics/04-reliability | config-guide (circuit_breaker), patterns #2 Equipment Lifecycle |
| 13.15 | Compensation / saga pattern | simulator-mechanics/10-approval-dlq | translation-guide §13 Financial Services |
| 13.16 | Parallel split & join (fork-join) | simulator-mechanics/03-flow-control | patterns #8 Parallel Processing, playbook-guide §fan-in-fan-out |
| 13.17 | Time windows (schedule gate) | simulator-mechanics/08-scheduling | team-department-modeling §7, translation-guide §8 Software Dev |
| 13.18 | Item cost accumulation | simulator-mechanics/06-value-economics | patterns #5 Budget Tracker, config-guide (Value Economics) |
| 13.19 | Adaptive concurrency (auto-scale) | simulator-mechanics/03-flow-control | archetypes §2 Virtual Flow |
| 13.20 | Rate limiter / token bucket | simulator-mechanics/03-flow-control | translation-guide §13 Financial Services |
| 13.21 | Probabilistic outcomes (Monte Carlo) | simulator-mechanics/04-reliability | patterns #4 Quality Gate, config-guide (fail_chance) |
| 13.22 | Audit trail on item | simulator-mechanics/11-observation | translation-guide §6 Compliance |
| 13.23 | Simulation context & scenarios | simulator-mechanics/11-observation, 13-clock-context | archetypes §5 Hybrid |
| 13.24 | Dead letter queue & replay | simulator-mechanics/10-approval-dlq | patterns #4 Quality Gate, #12 Rework with Escalation |
| 13.25 | Observation tap (non-consuming) | simulator-mechanics/11-observation | translation-guide §17 Pharma |
| 13.26 | Versioned item types (schema evolution) | simulator-mechanics/11-observation | — |
| 13.27 | Human-in-the-loop (approval gate) | simulator-mechanics/10-approval-dlq | patterns #7 Approval Workflow, team-department-modeling §6 |
| 13.28 | Simulation clock & fast-forward | simulator-mechanics/13-clock-context | — |
| 13.29 | Warmup period | simulator-mechanics/08-scheduling | config-guide (warmup_ticks), archetypes §1 Physical Flow |
| 13.30 | Yield rate | simulator-mechanics/09-data-routing | config-guide (yield_rate), archetypes §1 Physical Flow |
| 13.31 | Preventive maintenance | simulator-mechanics/08-scheduling | patterns #2 Equipment Lifecycle, archetypes §1 |
| 13.32 | Block priority | simulator-mechanics/01-node-types | — |
| 13.33 | Energy cost | simulator-mechanics/06-value-economics | patterns #5 Budget Tracker, archetypes §1 Physical Flow |

**Coverage summary**: All 33 mechanics have a primary topic file in simulator-mechanics. 30 of 33 are cross-referenced in at least one other skill. Mechanics 13.26 (schema evolution), 13.28 (simulation clock), and 13.32 (block priority) are only documented in their primary topic file.

---

## 3. Domain Coverage Matrix

All 19 domains from the simulator-translation-guide mapped across skills.

| # | Domain | Translation Guide | Archetypes | Patterns | Config Guide | Team Modeling | Playbook Guide |
|---|---|---|---|---|---|---|---|
| 1 | Workforce | §1 | Knowledge-Driven | #1 Employee Shift | ✅ Scheduled Source | ✅ Steps 1–8 | ✅ Calendar |
| 2 | Equipment | §2 | Physical Flow | #2 Equipment Lifecycle | ✅ Manufacturing Machine | — | ✅ Reliability |
| 3 | Logistics | §3 | Physical Flow | #3 Supply Chain | — | — | ✅ Routing |
| 4 | Finance | §4 | Hybrid | #5 Budget Tracker | — | — | — |
| 5 | Quality | §5 | Physical Flow | #4 Quality Gate | — | — | ✅ Quality Gate |
| 6 | Compliance | §6 | Approval-Heavy | #7 Approval Workflow | — | — | — |
| 7 | IT Operations | §7 | Virtual Flow | #6 Incident Pipeline | ✅ API Endpoint | — | — |
| 8 | Software Development | §8 | Virtual Flow | #9 Sprint Cycle | ✅ Software Dev Person | ✅ Full Worked Example | — |
| 9 | Human Resources | §9 | Approval-Heavy | — | — | — | — |
| 10 | Healthcare & Clinical | §10 | Hybrid | — | — | ✅ Hospital Ward | — |
| 11 | Education & Training | §11 | Knowledge-Driven | — | — | — | — |
| 12 | Retail & E-Commerce | §12 | Hybrid | — | — | — | — |
| 13 | Financial Services | §13 | Approval-Heavy | — | — | — | — |
| 14 | Insurance & Claims | §14 | Approval-Heavy | — | — | — | — |
| 15 | Energy & Utilities | §15 | Physical Flow | — | — | — | — |
| 16 | Construction | §16 | Physical Flow | — | — | — | — |
| 17 | Pharmaceutical | §17 | Hybrid | — | — | — | — |
| 18 | Public Sector | §18 | Approval-Heavy | — | — | — | — |
| 19 | Knowledge Services | §19 | Knowledge-Driven | — | — | — | — |

**Coverage summary**: All 19 domains have translation-guide keyword tables and archetype classification. Only 8 domains (1–8) have matching patterns. Only 4 domains have config-guide examples. Only 3 domains have team-modeling coverage. Domains 9–19 rely solely on keyword tables and archetype guidance.

---

## 4. Archetype Coverage Matrix

| Archetype | Domains (count) | Matching Patterns | Key Skills |
|---|---|---|---|
| Physical Flow | Equipment, Logistics, Quality, Energy & Utilities, Construction (5) | #2 Equipment Lifecycle, #3 Supply Chain, #4 Quality Gate | simulator-mechanics/04,08,09; config-guide (yield, warmup, circuit_breaker) |
| Virtual Flow | IT Operations, Software Development (2) | #6 Incident Pipeline, #9 Sprint Cycle, #13 Mentor Pair | simulator-mechanics/03,04; config-guide (concurrency); team-department-modeling |
| Approval-Heavy | Compliance, Human Resources, Financial Services, Insurance, Public Sector (5) | #7 Approval Workflow | simulator-mechanics/10; config-guide (Approval Gate) |
| Knowledge-Driven | Workforce, Education & Training, Knowledge Services (3) | #1 Employee Shift, #10 Team Handoff | team-department-modeling; config-guide (Scheduled Source) |
| Hybrid | Finance, Healthcare, Retail, Pharmaceutical (4) | #5 Budget Tracker, #11 Department Pipeline | simulator-mechanics/12 (composites); domain-process-archetypes §5 |

**Coverage summary**: Physical Flow and Virtual Flow have the deepest pattern coverage. Approval-Heavy has only one dedicated pattern despite covering 5 domains. Knowledge-Driven and Hybrid archetypes lean on team-department-modeling and composites rather than standalone patterns.

---

## 5. Example File Inventory

| # | Skill | Example Files | File Types |
|---|---|---|---|
| 1 | block-configuration-guide | 12 | .yaml (8), .txt (4) |
| 2 | business-process-mapping | 5 | .txt (3), .yaml (2) |
| 3 | data-pipeline | 3 | .txt (1), .py (2) |
| 4 | domain-process-archetypes | 0 | — |
| 5 | duckdb-analytics | 7 | .sql (5), .py (1), .txt (1) |
| 6 | migration-nextjs | 1 | .txt (1) |
| 7 | react-nextjs | 4 | .txt (1), .ts (3) |
| 8 | simulator-mechanics | 91 | .yaml (70), .py (18), .sql (2), .json (1) |
| 9 | simulator-patterns | 13 | .yaml (13) |
| 10 | simulator-playbook-guide | 16 | .yaml (16) |
| 11 | simulator-templates | 7 | .yaml (6), .py (1) |
| 12 | simulator-translation-guide | 8 | .yaml (7), .txt (1) |
| 13 | tailwind-css | 4 | .tsx (3), .js (1) |
| 14 | team-department-modeling | 25 | .yaml (23), .txt (2) |
| 15 | yaml-authoring | 2 | .yaml (2) |

**Totals**: 198 example files — 147 YAML, 22 Python, 12 text, 7 SQL, 7 TypeScript/TSX, 2 JavaScript, 1 JSON.

---

## 6. Coverage Gaps

### Mechanics with no worked example outside simulator-mechanics

- **13.26 Versioned item types (schema evolution)** — documented in 11-observation.md only, not referenced by any pattern, config guide, or domain skill.
- **13.28 Simulation clock & fast-forward** — documented in 13-clock-context.md only, no pattern or config-guide coverage.
- **13.32 Block priority** — mentioned in node-types topic but has no dedicated pattern, sizing heuristic, or domain example.

### Domains with keyword tables only (no pattern or worked example)

- **§9 Human Resources & Recruitment** — translation-guide table exists, archetype assigned, but no pattern, config example, or team-modeling variant.
- **§11 Education & Training** — translation-guide table only.
- **§12 Retail & E-Commerce** — translation-guide table only.
- **§13 Financial Services & Trading** — extensive keyword table (21 entries) but no dedicated pattern or config example.
- **§14 Insurance & Claims** — translation-guide table only.
- **§15 Energy & Utilities** — translation-guide table only.
- **§16 Construction & Engineering** — translation-guide table only.
- **§17 Pharmaceutical & Life Sciences** — translation-guide table only.
- **§18 Public Sector & Government** — translation-guide table only.
- **§19 Knowledge Services & Consulting** — translation-guide table only.

### Archetypes with thin pattern coverage

- **Approval-Heavy** — covers 5 domains but has only 1 pattern (#7 Approval Workflow). No patterns for multi-level approval chains, escalation paths, or committee-based decisions.
- **Knowledge-Driven** — covers 3 domains but has no dedicated archetype-specific pattern. Relies on team-department-modeling patterns which focus on software development.
- **Hybrid** — covers 4 domains but has no pattern demonstrating cross-layer composite coordination described in the archetype definition.

### Skills with minimal content

- **domain-process-archetypes** — 0 example files. Classification is comprehensive but has no YAML examples to copy.
- **data-pipeline** — 45 lines, 3 examples. Thin compared to the scope of DuckDB + JSONL data lake design.
- **duckdb-analytics** — 45 lines, 7 examples. Query patterns exist but no end-to-end KPI dashboard examples.
- **react-nextjs** — 39 lines, 4 examples. Minimal for the scope of Next.js App Router + SSE integration.
- **tailwind-css** — 38 lines, 4 examples. Covers basics but no dark mode, animation, or responsive variant guidance.

---

## 7. Skill Loading Quick Reference

| Task Type | Load These Skills |
|---|---|
| "Model a [business] department" | team-department-modeling, business-process-mapping, domain-process-archetypes |
| "Create a playbook for [industry]" | simulator-translation-guide, simulator-playbook-guide, simulator-patterns |
| "What mechanic for [concept]?" | simulator-translation-guide, simulator-mechanics (specific topic file) |
| "Size parameters for [block]" | block-configuration-guide |
| "Build a [domain] team structure" | team-department-modeling, simulator-translation-guide |
| "Add reliability to a block" | simulator-mechanics/04-reliability, block-configuration-guide |
| "Model approval workflow" | simulator-mechanics/10-approval-dlq, simulator-patterns (#7) |
| "Query simulation logs" | duckdb-analytics, data-pipeline |
| "Build React dashboard" | react-nextjs, tailwind-css, migration-nextjs |
| "Use a library template" | simulator-templates, yaml-authoring |
| "Classify a business by archetype" | domain-process-archetypes, simulator-translation-guide |
| "Add scheduling/calendar" | simulator-mechanics/08-scheduling, simulator-playbook-guide |
| "Model equipment lifecycle" | simulator-mechanics/04-reliability, block-configuration-guide, simulator-patterns (#2) |
| "Wire signals between blocks" | simulator-mechanics/05-signals-events |
| "Track costs through the graph" | simulator-mechanics/06-value-economics, block-configuration-guide |
| "Model composites (teams/departments)" | simulator-mechanics/12-composite, team-department-modeling |
| "Validate YAML structure" | yaml-authoring, simulator-playbook-guide |
| "Translate business interview to model" | business-process-mapping, simulator-translation-guide, domain-process-archetypes |
