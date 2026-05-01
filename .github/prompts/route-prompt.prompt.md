---
description: "Find the best existing prompt for a user's request and return its name, agent, and a filled-in invocation example."
agent: "Manager"
---
# Route Prompt

## Goal
- Identify the single most appropriate prompt for a user's request so the user can invoke it immediately without guessing.

## Inputs
- User's request description (natural language).
- Optional: known agent name or domain constraint.

## Steps
1. Load [skill: agent-routing](../skills/agent-routing/SKILL.md) and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Map the request to a primary domain: Rust engine code, Lua API design, Lua scripting/content, CAG layer, build/CI, documentation, roadmap/planning, testing, or performance analysis.
3. From `docs/architecture/cag-system.md § 4.1`, identify the owning agent for that domain.
4. List every `agent: "<owner>"` prompt in `.github/prompts/` whose `description` overlaps the request. Do not invent names — only list files that exist.
5. Score candidates: prefer the narrowest-scope prompt over a workflow-level prompt when the request is a single well-scoped task. State the score reason in one sentence per candidate.
6. Return: (a) the best prompt filename, (b) its agent, (c) the skills it loads, and (d) a filled-in invocation line using real values from the request — no placeholders. If no prompt matches, state that explicitly and name the agent to route to directly.

## Success Criteria
- [ ] Exactly one prompt is nominated, or zero with a clear explanation.
- [ ] The nominated prompt's agent matches the domain of the request.
- [ ] The invocation line uses real values, not placeholder names.
- [ ] If multiple prompts are close, the score reasoning is stated.
- [ ] No invented prompt filenames appear in the output.

## Anti-patterns
- Listing multiple prompts without choosing one.
- Choosing a workflow-level prompt when a targeted single-task prompt exists.
- Inventing prompt filenames that do not exist in `.github/prompts/`.
- Skipping the agent-to-domain mapping step and guessing from description alone.

## Example Invocation
- /route-prompt request="fix a crash in src/physics when spawning many bodies"
- /route-prompt request="add a Lua example showing timer.after usage"
- /route-prompt request="add a new lurek.net module with UDP support"

## CAG Metadata
Mode: agent
Loads skills: agent-routing, documentation
Inputs required: User's request description., Optional agent or domain constraint.
