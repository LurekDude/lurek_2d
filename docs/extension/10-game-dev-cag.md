# Luna Toolkit — Game Developer CAG Layer

> A self-contained AI-first workflow layer for **game developers** using Luna2D.
> This is NOT for engine developers. These agents, skills, prompts, and instructions
> are designed for people MAKING GAMES with Luna2D.
>
> Target user: A solo dev or small team writing Lua scripts for a 2D game.
> Deployment: Copied into the game project's `.github/` folder by the extension.

---

## Architecture Overview

```
vscode-extension/
└── cag/
    └── game-dev/
        ├── README.md                        ← game-dev CAG map
        ├── agents/
        │   ├── README.md
        │   ├── game-architect.agent.md
        │   ├── level-designer.agent.md
        │   ├── lua-scripter.agent.md
        │   ├── visual-artist.agent.md
        │   ├── audio-designer.agent.md
        │   ├── ui-designer.agent.md
        │   ├── animator.agent.md
        │   ├── gameplay-designer.agent.md
        │   ├── narrative-writer.agent.md
        │   ├── game-tester.agent.md
        │   └── optimizer.agent.md
        ├── skills/
        │   ├── platformer-movement/SKILL.md
        │   ├── top-down-movement/SKILL.md
        │   ├── camera-system/SKILL.md
        │   ├── animation-state-machine/SKILL.md
        │   ├── collision-response/SKILL.md
        │   ├── input-handling/SKILL.md
        │   ├── inventory-system/SKILL.md
        │   ├── save-load/SKILL.md
        │   ├── scene-management/SKILL.md
        │   ├── audio-manager/SKILL.md
        │   ├── ui-hud/SKILL.md
        │   ├── particle-juice/SKILL.md
        │   ├── tilemap-world/SKILL.md
        │   ├── pathfinding-ai/SKILL.md
        │   ├── combat-system/SKILL.md
        │   ├── crafting-system/SKILL.md
        │   ├── dialogue-system/SKILL.md
        │   ├── quest-tracker/SKILL.md
        │   ├── procedural-gen/SKILL.md
        │   ├── game-states/SKILL.md
        │   ├── object-pool/SKILL.md
        │   ├── event-bus/SKILL.md
        │   ├── tween-easing/SKILL.md
        │   ├── weather-vfx/SKILL.md
        │   ├── debug-console/SKILL.md
        │   └── leaderboard/SKILL.md
        ├── prompts/
        │   ├── new-game.prompt.md
        │   ├── add-player.prompt.md
        │   ├── add-enemy.prompt.md
        │   ├── add-level.prompt.md
        │   ├── add-ui.prompt.md
        │   ├── add-dialog.prompt.md
        │   ├── add-quest.prompt.md
        │   ├── add-save.prompt.md
        │   ├── optimize-performance.prompt.md
        │   ├── add-audio.prompt.md
        │   ├── add-animation.prompt.md
        │   ├── game-jam-kickstart.prompt.md
        │   ├── post-mortem.prompt.md
        │   ├── write-readme.prompt.md
        │   └── add-localization.prompt.md
        ├── instructions/
        │   ├── lua-game.instructions.md     (applyTo: **/*.lua)
        │   ├── main.instructions.md         (applyTo: main.lua)
        │   ├── entities.instructions.md    (applyTo: **/entities/*.lua)
        │   ├── assets.instructions.md      (applyTo: **/assets/**)
        │   ├── saves.instructions.md       (applyTo: **/saves/*.lua)
        │   ├── ui.instructions.md          (applyTo: **/ui/*.lua)
        │   ├── audio.instructions.md       (applyTo: **/audio/*.lua)
        │   └── physics-game.instructions.md (applyTo: **/physics/*.lua)
        └── templates/
            ├── minimal/
            ├── game-loop/
            ├── platformer/
            ├── top-down-rpg/
            ├── shoot-em-up/
            ├── puzzle/
            ├── roguelike/
            ├── visual-novel/
            ├── arcade/
            ├── tower-defense/
            ├── game-jam/
            └── demo-scene/
```

---

## Agents

### 1. game-architect
**Mission**: Design game systems and architecture before implementation begins.
**Asks about**: ECS vs tables, state machine structure, how systems communicate,
what to load at startup vs lazily, what global vs local state makes sense.
**Does not**: Write code. Produces design documents and system diagrams in ASCII.

```yaml
# Frontmatter
description: >
  Design the architecture for a Luna2D game. Decompose the game into systems,
  define data flow, propose module structure, identify shared state.
  Does not write Lua code.
model: claude-sonnet-4-5
tools: [read_file, file_search, semantic_search]
```

### 2. level-designer
**Mission**: Help design game levels, puzzles, progression curves, difficulty tuning.
**Asks about**: What genre, number of levels, intended playtime, skill progression,
how much challenge is appropriate at each point.
**Outputs**: Level briefs, encounter tables, tilemap layout suggestions,
pacing notes, difficulty curves.

```yaml
description: >
  Design levels, puzzles, encounter tables and progression curves for a Luna2D game.
  Outputs design documents and tilemap layout specs, not Lua code.
```

### 3. lua-scripter
**Mission**: Write production Lua code for the game using luna.* APIs.
**Considers**: LuaJIT best practices, avoiding hot-path allocations, proper use of
local variables, safe error handling, clean module structure.
**Does not**: Write Rust engine code. All code targets the luna.* Lua API surface.

```yaml
description: >
  Implement Luna2D game features in Lua. Writes production Lua code using
  luna.* APIs. Follows LuaJIT best practices. Does not modify Rust engine code.
tools: [read_file, replace_string_in_file, create_file, run_in_terminal]
```

### 4. visual-artist
**Mission**: Advise on visual design, colour palettes, sprite sizing, tileset organization.
**Asks about**: Game resolution, pixel art vs smooth art, colour palette size,
tile grid size, sprite sheet layout, animation frame budget.
**Outputs**: Palette recommendations (hex codes), tileset layout plans,
sprite sheet grids, visual style guides.

```yaml
description: >
  Advise on visual design for a Luna2D game: colour palettes, sprite sizing,
  tileset layout, animation frame budget. Not a code agent — outputs design specs.
```

### 5. audio-designer
**Mission**: Design the audio architecture and advise on sound placement.
**Asks about**: BGM style, SFX needs, channel layout, looping points, format choice.
**Outputs**: Audio channel map, sound effect list with trigger events,
BGM transition rules, volume budget.

```yaml
description: >
  Design the audio architecture for a Luna2D game: channel layout, BGM transitions,
  SFX trigger mapping, volume budget. Outputs audio design documents.
```

### 6. ui-designer
**Mission**: Design UI screens, HUD elements, menu flows, and accessibility.
**Asks about**: Screen size, target audience, what information must be always visible,
menu structure (title → play → pause → game over).
**Outputs**: UI wireframes (ASCII), HUD element list, menu flow diagram,
font size recommendations, accessibility notes.

```yaml
description: >
  Design UI screens, HUD elements, menus, and accessibility for a Luna2D game.
  Produces wireframes and flow diagrams, not Lua code.
```

### 7. animator
**Mission**: Design animation state machines, frame sequences, and blend logic.
**Asks about**: Character actions that need animation, sprite sheet structure,
how states transition, what triggers each animation.
**Outputs**: State machine diagram, frame table specifications, transition rules.

```yaml
description: >
  Design sprite animation state machines and frame sequences for a Luna2D game.
  Outputs animation design specs compatible with the Sprite Sheet Editor.
```

### 8. gameplay-designer
**Mission**: Design game mechanics, feel, controls, feedback loops, and game juice.
**Considers**: Coyote time, jump buffering, knockback feel, screen shake, hitstop,
combo systems, progression rewards.
**Outputs**: Mechanic spec documents with before/after feel comparisons,
parameter tuning tables, juice checklist.

```yaml
description: >
  Design game mechanics and "game feel" for a Luna2D game. Produces mechanic
  spec documents, parameter tables, and juice checklists. Not a code agent.
```

### 9. narrative-writer
**Mission**: Write in-game dialog, quest descriptions, item names, codex entries.
**Asks about**: Tone, world lore, character voices, reading level, narrative scope.
**Outputs**: Dialog trees in TOML/CSV, quest definition tables, lore entries.

```yaml
description: >
  Write narrative content for a Luna2D game: dialog trees, quest descriptions,
  item lore, codex entries. Outputs structured text ready for the Dialog Editor.
```

### 10. game-tester
**Mission**: Design test plans, edge case lists, balance spreadsheets.
**Asks about**: What can break, what the hardest part of the game is, what
players might try that wasn't intended.
**Outputs**: Test matrix spreadsheet (exported as CSV/TOML), edge case list,
balance comparison tables, known issues log.

```yaml
description: >
  Design test plans, edge case lists, and balance spreadsheets for a Luna2D game.
  Does not write code — produces structured testing documents and QA plans.
```

### 11. optimizer
**Mission**: Identify performance bottlenecks in game Lua code and propose fixes.
**Considers**: LuaJIT trace compilation, hot-path allocations, draw call batching,
physics step budget, Lua↔C call overhead.
**Outputs**: Profiling report with hot functions identified, recommended fixes
ranked by effort/impact, before/after pseudocode comparisons.

```yaml
description: >
  Profile and optimize Lua game code for Luna2D. Identifies LuaJIT hot-path issues,
  allocation patterns, and rendering bottlenecks. Produces optimization reports.
```

---

## Skills

### Skill Map by Domain

| Domain | Skill |
|---|---|
| **Movement** | platformer-movement, top-down-movement |
| **Camera** | camera-system |
| **Animation** | animation-state-machine |
| **Physics** | collision-response |
| **Input** | input-handling |
| **Game Object** | object-pool, event-bus |
| **Game State** | game-states, scene-management |
| **UI** | ui-hud, tween-easing |
| **Combat/Systems** | combat-system, crafting-system, inventory-system |
| **Story** | dialogue-system, quest-tracker |
| **World** | tilemap-world, procedural-gen, weather-vfx |
| **AI** | pathfinding-ai |
| **Audio** | audio-manager |
| **Polish** | particle-juice |
| **Meta** | save-load, debug-console, leaderboard |

### Skill Detail Specifications

#### `platformer-movement`
**Covers**: Jump arc & double jump, coyote time (3–8 frame window), jump buffering
(6-frame input queue), variable jump height (hold for higher), wall slide + wall jump,
ledge grab, platform passthrough (one-way colliders), run vs walk speed, acceleration curves.

**Key parameters to expose**:
```lua
PLAYER_SPEED      = 160   -- px/s walk
PLAYER_RUN_SPEED  = 280   -- px/s run
PLAYER_JUMP_VEL   = -420  -- px/s initial jump (negative = up)
GRAVITY           = 900   -- px/s²
COYOTE_FRAMES     = 6     -- frames after leaving edge still jumpable
JUMP_BUFFER_FRAMES = 8    -- frames before landing jump still counted
MAX_FALL_SPEED    = 600   -- px/s terminal velocity
```

---

#### `top-down-movement`
**Covers**: 8-directional movement, grid-locked movement (RPG style), diagonal
normalization (prevent 1.41× speed on diagonal), facing direction tracking,
turning animation timing, bump/slide collision response.

---

#### `camera-system`
**Covers**: Follow with lerp (configurable lag), room-locked camera (snap to bounds),
deadzone (small movement doesn't move camera), screenshake (trauma-based decay),
camera bounds (never show outside-of-level), zoom, look-ahead in movement direction.

**Code pattern**:
```lua
-- Minimal camera follow with smoothing
local function updateCamera(cam, target, dt)
    local speed = 8  -- higher = tighter follow
    cam.x = cam.x + (target.x - cam.x) * speed * dt
    cam.y = cam.y + (target.y - cam.y) * speed * dt
end
```

---

#### `animation-state-machine`
**Covers**: Sprite animation driven by state, transition conditions (velocity, grounded,
action), priority system (attack > die > walk > idle), one-shot animations that
return to idle, looping vs non-looping, frame events (trigger SFX at frame N).

---

#### `collision-response`
**Covers**: Luna2D Body collision callbacks, bounce, slide, separate-from-wall,
one-way platforms (pass through from below), slopes (project velocity along slope),
damage zones, ladder triggers.

---

#### `input-handling`
**Covers**: Action map pattern (abstract key → action), just-pressed vs held vs
just-released, gamepad support, configurable bindings, input buffering for combos,
deadzone handling.

---

#### `inventory-system`
**Covers**: Item table structure, stack management (stackable vs unique), max stack
size, transfer between inventories, drag-and-drop state, serialization to save file,
equipped vs unequipped distinction.

---

#### `save-load`
**Covers**: Which data must be saved (progress, settings, inventory), TOML format
for human-readable saves, versioning (`save_version` field), migration for old saves,
autosave on level transition, multiple save slots, validation on load.

```lua
-- Minimal save structure
local save = {
  save_version = 1,
  player = { x=100, y=200, hp=80, max_hp=100 },
  flags = { intro_seen=true, key_found=false },
  settings = { volume=0.8, fullscreen=false },
}
```

---

#### `scene-management`
**Covers**: Scene table pattern ({load, update, draw, unload}), transition effects
(fade black, wipe, dissolve), scene stack (push pause screen on top of game),
preloading next scene, asset cleanup on unload.

---

#### `audio-manager`
**Covers**: BGM: play, crossfade, stop, current track tracking. SFX: play at volume,
spatial (distance-based volume), priority (don't drop important SFX), random pitch
variation for variety, mute groups.

---

#### `ui-hud`
**Covers**: Health bar (gradients, damage flash), minimap (texture or simple point map),
inventory slot grid, popup tooltip, damage numbers (floating text), cooldown indicators,
dialog speech bubbles, ammo/resource meters.

---

#### `particle-juice`
**Covers**: On-hit sparks, walk dust, landing impact, death explosion, coin collect,
healing shimmer, level-up burst, screenshake-synchronized particles. All defined
as `luna.particle.newSystem()` configurations.

---

#### `tilemap-world`
**Covers**: Loading a tilemap from TOML, rendering layers in order (background/mid/
foreground), collision shape extraction from tile properties, auto-tiling at runtime,
camera bounds from map size, trigger zones.

---

#### `pathfinding-ai`
**Covers**: A* on grid (walkability from tilemap), smooth path following with
steering, obstacle avoidance, detection radius (aggro/deaggro), different AI modes
(patrol, chase, flee, guard), formation movement for groups.

---

#### `combat-system`
**Covers**: Hitbox/hurtbox separation, invincibility frames (i-frames), knockback
(apply impulse), damage numbers, on-death drop tables, team/faction system,
hit stop (pause for N frames on heavy hit), combo counters.

---

#### `crafting-system`
**Covers**: Recipe table (required items → output), fuzzy matching (any wood type),
multiple output quantities, crafting station restriction, discovery system (see
result before you have materials).

---

#### `dialogue-system`
**Covers**: Dialog node tree (speaker, text, choices, conditions, flags), portrait
images, typewriter effect, skip to end on confirm, conditional branches (require flag),
shop/trade as special dialog node types.

---

#### `quest-tracker`
**Covers**: Quest table (id, title, objectives[], state), objective types (reach,
collect, kill, talk), multi-step quests, side quests vs main quests, journal UI
entries, completion rewards (xp, items, flags).

---

#### `procedural-gen`
**Covers**: Dungeon room generation (BSP or cellular automata), corridor connection,
loot table (weighted random), enemy placement rules, secret room proportion, seeded
random for replay.

---

#### `game-states`
**Covers**: State stack: push/pop for pause, game-over, cutscene. State table:
{enter, exit, update, draw}. Transition animations. Persistent state that doesn't
reset on state change (e.g. HUD remains when pausing).

---

#### `object-pool`
**Covers**: Pre-allocated table of objects, acquire/release pattern, resize policy,
applying to bullets, particles, and enemies. Debug: show pool utilization overlay.

---

#### `event-bus`
**Covers**: Central event table: `on(event, handler)`, `emit(event, ...)`, `off(handler)`.
Use cases: player death notifies HUD notifies audio notifies save system — all
decoupled. Events scoped per scene or global.

---

#### `tween-easing`
**Covers**: Tween a number or table field over time (x, y, alpha, scale), built-in
easing functions, chain multiple tweens, callbacks on completion, cancel tween,
table of all easing function names with visual descriptions.

---

#### `weather-vfx`
**Covers**: Rain (vertical particles, splash on floor), snow (slow drift, accumulation
overlay), wind (horizontal force on particles), lightning (flash + delay thunder SFX),
fog (full-screen alpha overlay).

---

#### `debug-console`
**Covers**: Toggle overlay (F1/backtick), command input line, `register_command(name, fn)`,
built-in commands: `/fps`, `/reload`, `/setflag`, `/give`, `/teleport`, `/god`.
Minimal performance impact when hidden.

---

#### `leaderboard`
**Covers**: High score table (name, score, date), persist to save file, display sorted,
new high score flash, reset leaderboard command.

---

## Prompts (Playbooks)

Each prompt is a full task specification that orchestrates multiple agents.

### `new-game.prompt.md`
**Trigger**: User starts a new game project.
**Flow**:
1. Ask 5 key questions: genre, style, approx scope, team size, platform
2. Route to `game-architect` → produce system design
3. Route to `level-designer` → produce first area brief
4. Route to `lua-scripter` → scaffold from template
5. Route to `visual-artist` → colour palette + art direction

```yaml
---
name: New Luna2D Game
description: >
  Start a new Luna2D game project from scratch. Interviews the developer,
  selects a template, and wires up the first scene with correct architecture.
mode: ask  # always ask before executing
---
```

---

### `add-player.prompt.md`
**Trigger**: "add a player character to my game"
**Flow**:
1. Ask: genre context (platformer / top-down / etc.)
2. Load skill: `platformer-movement` or `top-down-movement`
3. Load skill: `animation-state-machine`
4. Load skill: `input-handling`
5. Route to `lua-scripter` → implement `entities/player.lua`
6. Verify: player loads, moves, animates

---

### `add-enemy.prompt.md`
**Trigger**: "add an enemy" or "add a [name] enemy"
**Flow**:
1. Ask: enemy type (patrol, chase, ranged, boss)
2. Load skills: `pathfinding-ai`, `combat-system`, `animation-state-machine`
3. Route to `lua-scripter` → implement `entities/enemy_[name].lua`
4. Route to `game-tester` → write edge case list for this enemy type

---

### `add-level.prompt.md`
**Trigger**: "add a new level" or "design level N"
**Flow**:
1. Ask: level theme, difficulty level, expected playtime
2. Route to `level-designer` → produce level brief
3. Route to `lua-scripter` → scaffold level Lua with spawn data
4. Route to `audio-designer` → advise BGM and ambient SFX for this level

---

### `add-ui.prompt.md`
**Trigger**: "add a HUD" or "add a pause menu" or "add UI"
**Flow**:
1. Ask: which screen (main menu / HUD / pause / game over / settings)
2. Route to `ui-designer` → produce wireframe
3. Load skill: `ui-hud`
4. Route to `lua-scripter` → implement in `ui/[name].lua`

---

### `add-dialog.prompt.md`
**Trigger**: "add dialog" or "add NPC conversation"
**Flow**:
1. Ask: character voice, dialog goal, branching or linear
2. Route to `narrative-writer` → write dialog tree
3. Load skill: `dialogue-system`
4. Export dialog to TOML format

---

### `add-save.prompt.md`
**Trigger**: "add save/load" or "implement saving"
**Flow**:
1. Ask: what data must be saved, single slot or multiple, autosave?
2. Load skill: `save-load`
3. Route to `lua-scripter` → implement `savegame/save.lua`
4. Add save/load tests

---

### `optimize-performance.prompt.md`
**Trigger**: "my game is slow" or "improve performance"
**Flow**:
1. Ask: target FPS, current FPS, which scene is slowest
2. Route to `optimizer` → review hot files, identify bottlenecks
3. Load skills: `object-pool`, `tilemap-world` (if relevant)
4. Route to `lua-scripter` → apply specific fixes
5. Measure: before/after FPS

---

### `game-jam-kickstart.prompt.md`
**Trigger**: "game jam" or "48-hour game"
**Flow**:
1. Ask: jam theme, time constraint, solo or team
2. Scaffold `game-jam` template immediately (no questions about architecture)
3. Route to `gameplay-designer` → 3 mechanic ideas in 5 min
4. Select 1 mechanic → route to `lua-scripter` to implement core loop first
5. Time-box each feature

---

### `post-mortem.prompt.md`
**Trigger**: "game jam post-mortem" or "game review"
**Flow**:
1. Read `main.lua`, all `entities/`, `ui/`
2. Route to `game-tester` → identify what worked / broke
3. Route to `optimizer` → identify what was slow
4. Output structured post-mortem report: What Went Well / What Went Wrong / What to Do Next

---

### `write-readme.prompt.md`
**Trigger**: "write a README" or "document my game"
**Flow**:
1. Read `conf.lua`, `main.lua`, `README.md` if it exists
2. Route to `Doc-Writer`-equivalent → generate README.md with:
   - Game description, screenshots placeholder, controls, install, build, license

---

### `add-localization.prompt.md`
**Trigger**: "add localization" or "add translation"
**Flow**:
1. Ask: which languages, which locale is the source
2. Load skill: Extract all string literals from Lua files → build key list
3. Route to `lua-scripter` → implement `i18n/locale.lua`
4. Generate `i18n/en.toml` with all extracted strings
5. Open Localization Editor for remaining translations

---

## Instructions (Always-Loaded Context)

### `lua-game.instructions.md`
```markdown
---
applyTo: "**/*.lua"
---
# Luna2D Lua Game Conventions
- Use `local` for all game-internal variables and functions
- Never `require` inside function bodies in hot paths
- Always call `luna.load()` once and cache expensive resources there
- Prefer event-based communication between systems (Event Bus pattern)
- Game-specific errors use `error("context: message")` with a module prefix
- Comments explain WHY something is done, not WHAT it does
- Numbers in physics are in pixels — document units in comments
- Color values are ALWAYS 0-1 range, not 0-255
```

### `main.instructions.md`
```markdown
---
applyTo: "main.lua"
---
# main.lua Structure Rules
- main.lua ONLY: require modules, call init, wire callbacks
- Never put game logic directly in main.lua; delegate to modules
- Required callbacks: luna.load, luna.update, luna.draw
- Optional callbacks: luna.keypressed, luna.keyreleased, luna.mousepressed,
  luna.mousereleased, luna.focus, luna.resize, luna.quit
- conf.lua must exist and define window.title minimally
```

### `entities.instructions.md`
```markdown
---
applyTo: "**/entities/*.lua"
---
# Entity Module Rules
- Every entity file exports one table: the entity class/factory
- Constructor pattern: Entity.new(params) → setmetatable({}, Entity)
- Required methods: :update(dt), :draw()
- Optional: :destroy(), :onCollision(other), :serialize()
- Entity state is never stored in global — always instance fields
- Entities communicate via Event Bus, not direct references
```

### `assets.instructions.md`
```markdown
---
applyTo: "assets/**"
---
# Asset Organization Rules
- assets/sprites/    — PNG sprite sheets, tiles
- assets/audio/      — OGG vorbis sounds and music
- assets/fonts/      — TTF or bitmap font files
- assets/maps/       — TOML tilemap files
- assets/data/       — TOML game data (items, enemies, quests)
- All audio files MUST be OGG Vorbis for cross-platform compatibility
- All sprite sheets MUST be PNG with power-of-two dimensions
- File names are lowercase_with_underscores, no spaces
```

### `saves.instructions.md`
```markdown
---
applyTo: "**/saves/*.lua"
---
# Save System Rules
- All save data serializes to TOML via luna.data.encodeToml()
- ALWAYS include a `save_version` integer field
- ALWAYS validate save_version on load, migrate if needed
- NEVER store raw Lua function references in save data
- Save paths use luna.filesystem.getSaveDirectory()
- Validate save data before applying (nil-check every expected field)
```

---

## Project Templates

Each template is a directory tree ready to be scaffolded by the extension.
Located in `vscode-extension/cag/game-dev/templates/`.

### Template File Structure (minimal)

```
templates/minimal/
├── main.lua
├── conf.lua
└── README.md
```

```lua
-- conf.lua (all templates share this)
function luna.conf(cfg)
    cfg.window.title  = "My Luna2D Game"
    cfg.window.width  = 800
    cfg.window.height = 600
    cfg.window.vsync  = true
end
```

---

### Template 1: `minimal`
Just callbacks, no systems. For experiments.
```
main.lua   — 8 callbacks stubbed
conf.lua   — window config
README.md
```

---

### Template 2: `game-loop`
Full structure with common game loop patterns.
```
main.lua           — wires all modules
conf.lua
lib/
  class.lua        — simple OOP base
  events.lua       — event bus
assets/
entities/
ui/
saves/
```

---

### Template 3: `platformer`

```
main.lua
conf.lua
lib/ (class, events, input, camera)
entities/
  player.lua        — move/jump/double-jump, coyote time
  enemy_basic.lua   — patrol, aggro on sight
assets/
  sprites/          — placeholder sprite sheets
  maps/             — test_level.toml
  audio/
ui/
  hud.lua           — HP bar, coins
saves/
  save.lua          — checkpoint-based saves
```

---

### Template 4: `top-down-rpg`

```
main.lua
conf.lua
lib/
entities/
  player.lua        — 8-dir movement + interaction
  npc.lua           — dialog tree, wander
  enemy.lua         — pathfinding, combat
scenes/
  title.lua
  world.lua
  battle.lua
ui/
  dialog_box.lua
  hud.lua
  inventory_screen.lua
assets/
  sprites/
  maps/             — world_map.toml, town.toml, dungeon.toml
  data/
    items.toml
    npcs.toml
    quests.toml
  audio/
saves/
i18n/
  en.toml
```

---

### Template 5: `shoot-em-up`

```
main.lua
conf.lua
lib/ (class, events, pool, input)
entities/
  player.lua        — ship, fire bullets
  bullet_pool.lua   — object pool for player bullets
  enemy_*.lua       — various enemy types + patterns
  enemy_bullet_pool.lua
scenes/
  game.lua          — scrolling background + waves
  boss.lua          — boss state machine
  gameover.lua
ui/
  hud.lua           — lives, score, boss HP
assets/
  sprites/
  audio/
```

---

### Template 6: `puzzle`

```
main.lua
conf.lua
lib/ (class, events, tween, undo)
entities/
  grid.lua          — 2D grid abstraction
  tile.lua          — grid cell entity
  player_marker.lua — player position on grid
scenes/
  level.lua
  level_select.lua
assets/
  data/
    levels.toml     — encoded puzzle levels
  audio/
  sprites/
```

---

### Template 7: `roguelike`

```
main.lua
conf.lua
lib/ (class, events, rng, pool, astar)
generator/
  dungeon.lua       — BSP room generation
  loot.lua          — weighted loot tables
  mob_spawner.lua
entities/
  player.lua        — turn-based stats
  enemy.lua         — turn-based AI
scenes/
  dungeon.lua       — main game
  death.lua         — permadeath screen
  meta.lua          — meta progression
assets/
  data/
    enemies.toml
    items.toml
    dungeon_config.toml
```

---

### Template 8: `visual-novel`

```
main.lua
conf.lua
lib/ (class, events, tween)
story/
  ch01.toml         — TOML dialog trees
  ch02.toml
engine/
  dialog_runner.lua — executes story/chNN.toml
  character.lua     — portrait management
scenes/
  chapter.lua
  choices.lua
  gallery.lua
assets/
  backgrounds/
  portraits/
  audio/
  fonts/
saves/              — chapter + choice flags
```

---

### Template 9: `arcade`

```
main.lua
conf.lua
lib/ (class, events, pool)
entities/
  player.lua
  obstacle.lua
  collectible.lua
scenes/
  title.lua
  game.lua
  gameover.lua
  highscores.lua
assets/
  sprites/
  audio/
saves/
  leaderboard.toml
```

---

### Template 10: `tower-defense`

```
main.lua
conf.lua
lib/ (class, events, pool, astar, queue)
entities/
  tower/  (basic, sniper, splash, slow)
  enemy/  (infantry, armored, flying, boss)
  projectile_pool.lua
  waypoints.lua
scenes/
  map.lua
  wave_manager.lua
  shop.lua
ui/
  hud.lua        — gold, lives, wave counter
  tower_menu.lua
assets/
  data/
    towers.toml
    enemies.toml
    maps/
      level01.toml
```

---

### Template 11: `game-jam`
Stripped down — get to game loop in < 60 seconds.

```
main.lua          — callbacks + one State table
conf.lua          — 800×600 window
README.md         — jam entry notes
assets/
```

```lua
-- main.lua for game-jam template
local state = {
    load   = function() end,
    update = function(dt) end,
    draw   = function() end,
}

function luna.load()    state.load()    end
function luna.update(dt) state.update(dt) end
function luna.draw()    state.draw()    end

-- Replace state table to change what's running
```

---

### Template 12: `demo-scene`
Technical showcase / portfolio demo.

```
main.lua            — scene switcher via 1-9 keys
conf.lua
scenes/
  01_sprites.lua
  02_physics.lua
  03_particles.lua
  04_tilemap.lua
  05_audio.lua
  06_shader.lua
  07_entities.lua
assets/
```

---

## Deployment Mechanism

The extension writes the selected CAG layer into the game project:

```
[Luna Toolkit: Deploy Game Dev AI Layer]
    ↓
Select which components:
  ☑ Agents
  ☑ Skills (all or curated by template type)
  ☑ Prompts
  ☑ Instructions
  ☐ Project template (separate action)

Target: workspace-root/.github/
    ↓
Writes:
  .github/instructions/  → 8 instruction files
  .github/agents/        → 11 agent files
  .github/skills/        → selected skill folders
  .github/prompts/       → 15 prompt files
  .github/copilot-instructions.md → game-dev system prompt
```

### `copilot-instructions.md` (header injected by extension)

```markdown
# [Game Name] — AI Instructions

This is a Luna2D game project (NOT the engine itself).
Language: Lua (LuaJIT target). API: luna.*

## Project Type
[Filled by template: platformer / RPG / etc.]

## Key Systems
[Filled by extension from detected module structure]

## Luna2D API Quick Reference
All APIs are under luna.* — never external engine prefixes or third-party runtime prefixes.
Key modules: luna.graphics, luna.audio, luna.physics, luna.input,
  luna.math, luna.timer, luna.filesystem, luna.entity, luna.event

## Agent Map
- game-architect  → system design, architecture decisions
- lua-scripter    → Lua implementation
- gameplay-designer → mechanics, feel, tuning
[etc.]
```

---

## Configuration (package.json additions)

```jsonc
"luna.gameDevCag.autoInstall": {
  "type": "boolean", "default": false,
  "description": "Auto-install game-dev CAG on project creation"
},
"luna.gameDevCag.template": {
  "type": "string",
  "enum": ["minimal","game-loop","platformer","top-down-rpg","shoot-em-up",
           "puzzle","roguelike","visual-novel","arcade","tower-defense",
           "game-jam","demo-scene"],
  "default": "game-loop",
  "description": "Default project template"
},
"luna.gameDevCag.skills": {
  "type": "array", "default": [],
  "description": "Skills to include when deploying CAG. Empty = all."
},
"luna.gameDevCag.agents": {
  "type": "array", "default": [],
  "description": "Agents to include when deploying CAG. Empty = all."
}
```

---

## CAG Validation

The existing `tools/cag_validate.py` validates the engine-dev CAG in `.github/`.
The game-dev CAG inside `vscode-extension/cag/game-dev/` requires its own
validation step, invoked during the extension build:

```powershell
python tools/cag_validate.py --dir vscode-extension/cag/game-dev
```

Rules that differ from engine-dev validation:
- Agents must NOT reference engine source files (`src/`, `Cargo.toml`)
- Skill examples must use `luna.*` API only (never raw Rust types)
- All examples must be valid LuaJIT (no Lua 5.4-only syntax)
