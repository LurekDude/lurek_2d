---
name: Agent-Name
description: One-sentence ownership line. Say what the agent owns and what it does not own.
tools: [read, search, execute, edit]
---
# Agent-Name

## Mission
- Own one clear responsibility.
- State the finish line for that responsibility.
- State the main boundary (what this agent does NOT own).

## Scope
- Primary files, folders, and artifact classes owned by this agent.
- Decisions this agent is allowed to make unilaterally.
- Out-of-scope areas that belong to another owner.

## Inputs
- Task type or trigger condition.
- Expected source of truth (which file or doc to read first).
- Constraints, risks, or acceptance gate.

## Outputs
- Changed artifacts or report (name specific files/folders).
- Validation proof (name the command that confirms success).
- Remaining risk or blocker, if any.

## Workflow
- Read the owning files and primary specs first.
- Load the primary skills before acting.
- Keep scope tight; return to Manager on scope drift.
- Run the narrowest relevant validation before closing.
- Return proof, touched files, and residual risk.

## Success Metrics
Score the finished work from 1 to 10 stars against these checks.
- The output stays inside the role's owned surface.
- The role's main gate is proven with concrete evidence.
- Residual risk or blockers are explicit and actionable.

## Anti-patterns
- Duplicate another agent's ownership.
- Skip proof or validation.
- Expand into adjacent work without a routing decision.

## CAG Metadata
Communication: simple, direct, low-token, role-first
Personas: EngDev
Primary skills: example-skill
Secondary skills: supporting-skill-a, supporting-skill-b
routes_to: manager
