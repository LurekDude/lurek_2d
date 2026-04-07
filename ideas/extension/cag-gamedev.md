# Game-Dev CAG Layer Analysis

## Current State

### Documentation (10-game-dev-cag.md)

The doc specifies a **game developer-facing CAG layer** (separate from the engine CAG in `.github/`):

| Category | Count | Details |
|---|---|---|
| Agents | 11 | game-architect, level-designer, lua-scripter, visual-artist, audio-designer, ui-designer, animator, gameplay-designer, narrative-writer, game-tester, optimizer |
| Skills | 26 | Covering game systems, genres, patterns |
| Prompts | 15 | Common game development tasks |
| Instructions | 8 | Code style, naming, testing, patterns |
| Templates | 12 | Project scaffolds for different game genres |

### Implementation

| Component | File | Status |
|---|---|---|
| CAG commands | commands/cag.ts | install, selectAgent, selectSkill, selectPrompt |
| Game Dev commands | commands/gameDevCag.ts | deploy, scaffold, update + 12 templates |
| CAG assets | cag/game-dev/ | Folder exists with agents/, instructions/, skills/, templates/ |

**gameDevCag.ts findings**:
- 4 CAG component types: Agents, Skills, Prompts, Instructions (with source directory mapping)
- 12 game templates: minimal, game-loop, platformer, RPG, shooter, puzzle, roguelike, visual-novel, arcade, tower-defense, game-jam, demo-scene
- Helper functions: `copyDirRecursive()`, `countFiles()`, `getGameDevCagRoot()`
- Workspace root detection

---

## Improvement Ideas

### 1. Agent Specialization for Luna2D

**Problem**: The 11 game-dev agents are generic. They don't know about Luna2D-specific APIs.

**Improvement**:
- Each agent should reference the luna.* APIs relevant to its domain
- `lua-scripter` should know about luna.event, luna.timer, luna.entity
- `level-designer` should know about luna.tilemap, luna.scene, luna.physics
- `audio-designer` should know about luna.audio.* API
- `visual-artist` should know about luna.graphics, luna.particle, luna.animation
- Include API examples in agent system prompts

### 2. Template Quality Assessment

**12 templates exist**. Quality check needed:

| Template | Expected Content | Concern |
|---|---|---|
| minimal | main.lua + conf.lua | Should be < 20 lines |
| game-loop | update/draw loop | Should demonstrate delta time |
| platformer | physics + input | Should use luna.physics |
| rpg | entities + stats | Should use luna.entity + library/stats |
| shooter | physics + spawn | Should demonstrate bullet pools |
| puzzle | grid + input | Should demonstrate grid math |
| roguelike | procedural gen | Should use luna.math.noise |
| visual-novel | dialog + choices | Should use library/dialog |
| arcade | high score + lives | Should demonstrate luna.data |
| tower-defense | pathfinding + entities | Should use luna.pathfinding |
| game-jam | fast scaffold | Should be minimal + timer |
| demo-scene | graphics showcase | Should use multiple luna.graphics calls |

**Action**: Verify each template actually uses the relevant luna.* APIs and library/ modules.

### 3. Skill-Agent Mapping

**Gap**: No documented mapping between skills and agents.

**Improvement**: Define which skills each agent should load:

| Agent | Recommended Skills |
|---|---|
| game-architect | module-architecture, lua-api-design |
| level-designer | lua-scripting, tilemap design |
| lua-scripter | lua-scripting, lua-runtime, error-handling |
| visual-artist | gpu-programming, visual-effects |
| audio-designer | (new) audio-integration |
| ui-designer | lua-scripting, (new) gui-design |
| animator | (new) animation-patterns |
| gameplay-designer | game-ai, lua-scripting |
| narrative-writer | (new) dialog-systems |
| game-tester | testing-rust, lua-scripting |
| optimizer | performance-profiling |

### 4. Instruction Files Review

**8 instruction files** should cover:
1. Lua coding style (indentation, naming)
2. Luna2D API conventions (callbacks, lifecycle)
3. File organization (modules, require patterns)
4. Testing patterns (describe/it/expect)
5. Performance guidelines (avoid per-frame allocations)
6. Asset management (paths, formats, sizes)
7. Error handling (pcall patterns, defensive coding)
8. Documentation (comments, README per game module)

**Action**: Verify these match the engine's Lua API conventions from the system prompt.

### 5. Prompt Library Expansion

**15 prompts** for common tasks. Suggested additional prompts:
- "Add a new enemy type to my game"
- "Create a save/load system for my game"
- "Add particle effects to my game"
- "Implement a dialog system"
- "Add a minimap to my game"
- "Create a crafting system"
- "Add screen shake on impact"
- "Implement a combo system"
- "Add a day/night cycle"
- "Create a shop/merchant"

### 6. CAG Deployment Workflow

**Current**: `luna.cag.deploy` copies CAG files to the game project.

**Improvements**:
- Version the CAG files — track which version was deployed
- Diff before deploying (show what changed since last deploy)
- Selective deploy — choose which agents/skills to install
- Auto-update check — notify when new CAG content is available
- Dry-run mode — show what would be copied without actually copying

### 7. Template Live Preview

**Improvement**: Before scaffolding, show a preview of what will be generated.

- List of files that will be created
- Preview of main.lua content
- Estimated project structure
- "Customize before creating" option

### 8. Integration with Engine CAG

**Problem**: The game-dev CAG layer is separate from the engine CAG in `.github/`.

**Improvement**:
- Engine CAG agents (Developer, Tester, etc.) should be aware of game-dev CAG agents
- When a game developer asks an engine question, route to the engine agent
- When an engine developer asks about game patterns, reference game-dev skills
- Shared skill vocabulary between layers

### 9. Community Template Sharing

**Long-term feature**:
- Allow game developers to share templates
- Template repository (GitHub/registry)
- Rating/review system for templates
- "Fork and customize" workflow
- Versioned template updates
