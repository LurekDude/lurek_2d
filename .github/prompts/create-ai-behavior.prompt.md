---
description: "Create a new AI behavior for Lurek2D game entities. Use when implementing FSM states, behavior tree nodes, steering behaviors, or GOAP ac..."
agent: Developer
---
# Create Ai Behavior

## Goal

Create a new AI behavior for Lurek2D game entities. Use when implementing FSM states, behavior tree nodes, steering behaviors, or GOAP ac... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `SharedState` — value supplied by the user invocation.

## Steps

1. **Choose the AI model**
2. FSM: Simple state-based behavior (idle → patrol → chase)
3. BehaviorTree: Complex decision logic with fallbacks
4. Steering: Smooth movement (seek, flee, wander, flocking)
5. GOAP: Multi-step planning with preconditions/effects
6. QLearner: Learning from experience (small state spaces only)
7. UtilityAI: Weighted action scoring
8. **Implement the Rust type**
9. Add to appropriate file in `src/ai/`
10. Follow existing patterns (DecisionModel enum, Agent struct)
11. All computation must be pure CPU math — no GPU or window access
12. Add `///` doc comments on all public items

## Success Criteria

- [ ] New AI type compiles and passes tests
- [ ] Lua bindings work under `lurek.ai.*`
- [ ] Doc comments on all public items
- [ ] No GPU, audio, or window dependencies in `src/ai/`

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-ai-behavior <SharedState>`

## CAG Metadata

- **Mode**: agent
- **Inputs required**: SharedState
