> See [../examples/blackboard-shared-ai-memory.lua](../examples/blackboard-shared-ai-memory.lua) for the example.

---

### Steering Behaviours
Steering behaviours produce smooth movement forces combined by `SteeringManager`.

> See [../examples/steering-behaviours.lua](../examples/steering-behaviours.lua) for the example.

---

### GOAP — Goal-Oriented Action Planning
Best for emergent NPCs with many possible actions and multiple goals.

> See [../examples/goap-goal-oriented-action-planning.lua](../examples/goap-goal-oriented-action-planning.lua) for the example.

---

### Utility AI — Scored Action Selection
Best for NPCs that weigh many competing factors simultaneously.

> See [../examples/utility-ai-scored-action-selection.lua](../examples/utility-ai-scored-action-selection.lua) for the example.

---

### Squad — Group Formation
> See [../examples/squad-group-formation.lua](../examples/squad-group-formation.lua) for the example.

---

### Influence Map — Strategic Spatial Reasoning
> See [../examples/influence-map-strategic-spatial-reasoning.lua](../examples/influence-map-strategic-spatial-reasoning.lua) for the example.

---

### Testing AI
AI runs headlessly (no GPU, audio, or window needed):

> See [../examples/testing-ai.lua](../examples/testing-ai.lua) for the example.

**Rule**: Create a fresh `AIWorld` per test — worlds are stateful and must not leak across tests.
