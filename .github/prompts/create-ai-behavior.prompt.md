---
description: "Create a new lurek.ai behavior."
---

# Create Ai Behavior

## Goal
- Create a new AI behavior for Lurek2D game entities. Use when implementing FSM states, behavior tree nodes, steering behaviors, or GOAP ac...

## Inputs
- SharedState

## Steps
- **Choose the AI model**
- FSM: Simple state-based behavior (idle patrol chase)
- BehaviorTree: Complex decision logic with fallbacks
- Steering: Smooth movement (seek, flee, wander, flocking)
- GOAP: Multi-step planning with preconditions/effects
- QLearner: Learning from experience (small state spaces only)
- UtilityAI: Weighted action scoring
- **Implement the Rust type**
- Add to appropriate file in src/ai/
- Follow existing patterns (DecisionModel enum, Agent struct)
- All computation must be pure CPU math no GPU or window access
- Add /// doc comments on all public items

## Success Criteria
- [ ] New AI type compiles and passes tests
- [ ] Lua bindings work under lurek.ai.*
- [ ] Doc comments on all public items
- [ ] No GPU, audio, or window dependencies in src/ai/

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-ai-behavior <SharedState>

## CAG Metadata
- **Mode**: agent
- **Inputs required**: SharedState
