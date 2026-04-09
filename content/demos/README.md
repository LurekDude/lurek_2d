# Lurek2D Demos

111 fully playable demo games, organized by category. Plus 2 engine showcases.
Every demo is self-contained: run with `cargo run -- content/demos/<category>/<name>`.

For API reference code (not runnable games), see [`examples/`](../examples/).

---

## Running a Demo

```bash
cargo run -- content/demos/<category>/<name>          # debug build
cargo run --release -- demos/<category>/<name>  # release build
luna demos/<category>/<name>                  # installed binary
```

---

## Classic Arcade

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="arcade/pong/screen.png" width="160" height="120" alt="Pong"> | [Pong](arcade/pong) | Classic 2-player paddle game — first to 7 wins |
| <img src="arcade/pac_man/screen.png" width="160" height="120" alt="Pac Man"> | [Pac Man](arcade/pac_man) | Grid maze, 4 ghosts, dots and power pellets |
| <img src="arcade/tetris/screen.png" width="160" height="120" alt="Tetris"> | [Tetris](arcade/tetris) | 7 tetrominos, rotation, ghost piece, line clearing |
| <img src="arcade/snake/screen.png" width="160" height="120" alt="Snake"> | [Snake](arcade/snake) | Growing snake — eat food, avoid yourself |
| <img src="arcade/space_invaders/screen.png" width="160" height="120" alt="Space Invaders"> | [Space Invaders](arcade/space_invaders) | 11×5 invader grid, destructible barriers |
| <img src="arcade/galaga/screen.png" width="160" height="120" alt="Galaga"> | [Galaga](arcade/galaga) | Formation enemies with dive attacks and capture beam |
| <img src="arcade/asteroids/screen.png" width="160" height="120" alt="Asteroids"> | [Asteroids](arcade/asteroids) | Vector wireframe ship with inertia and splitting rocks |
| <img src="arcade/centipede/screen.png" width="160" height="120" alt="Centipede"> | [Centipede](arcade/centipede) | Mushroom field, segmented centipede, bouncing spider |
| <img src="arcade/frogger/screen.png" width="160" height="120" alt="Frogger"> | [Frogger](arcade/frogger) | Lane crossing, log riding, 5 lily-pad homes |
| <img src="arcade/donkey_kong/screen.png" width="160" height="120" alt="Donkey Kong"> | [Donkey Kong](arcade/donkey_kong) | Sloped platforms, rolling barrels, ladders |

## Retro Classics

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="retro/boulder_dash/screen.png" width="160" height="120" alt="Boulder Dash"> | [Boulder Dash](retro/boulder_dash) | Dig through a cave, collect diamonds to escape |
| <img src="retro/giana_sisters/screen.png" width="160" height="120" alt="Giana Sisters"> | [Giana Sisters](retro/giana_sisters) | Side-scrolling platformer — gems, enemies, exit |
| <img src="retro/commando/screen.png" width="160" height="120" alt="Commando"> | [Commando](retro/commando) | Vertical-scroll top-down shooter with grenades |
| <img src="retro/paradroid/screen.png" width="160" height="120" alt="Paradroid"> | [Paradroid](retro/paradroid) | Space station shooter with robot transfer minigame |
| <img src="retro/turrican/screen.png" width="160" height="120" alt="Turrican"> | [Turrican](retro/turrican) | Run-and-gun platformer with continuous energy beam |
| <img src="retro/lemmings/screen.png" width="160" height="120" alt="Lemmings"> | [Lemmings](retro/lemmings) | Assign jobs to guide lemmings to the exit |
| <img src="retro/cannon_fodder/screen.png" width="160" height="120" alt="Cannon Fodder"> | [Cannon Fodder](retro/cannon_fodder) | 3-man squad auto-fire shooter across 5 missions |
| <img src="retro/sensible_soccer/screen.png" width="160" height="120" alt="Sensible Soccer"> | [Sensible Soccer](retro/sensible_soccer) | 5v5 top-down football with CPU team AI |
| <img src="retro/another_world/screen.png" width="160" height="120" alt="Another World"> | [Another World](retro/another_world) | 3-scene cinematic platformer with shield deflection |
| <img src="retro/shadow_beast/screen.png" width="160" height="120" alt="Shadow Beast"> | [Shadow Beast](retro/shadow_beast) | Atmospheric parallax side-scroller — 3 stages |
| <img src="retro/raycaster_fps/screen.png" width="160" height="120" alt="Raycaster FPS"> | [Raycaster FPS](retro/raycaster_fps) | Wolfenstein-style FPS: textured walls, fog, items, weather |
| <img src="retro/dungeon_crawler/screen.png" width="160" height="120" alt="Dungeon Crawler"> | [Dungeon Crawler](retro/dungeon_crawler) | Eye of Beholder grid-step dungeon: torches, orbs, minimap |

## Sports

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="sports/tennis_classic/screen.png" width="160" height="120" alt="Tennis Classic"> | [Tennis Classic](sports/tennis_classic) | Top-down tennis — topspin, full scoring (Deuce/Adv) |
| <img src="sports/track_and_field/screen.png" width="160" height="120" alt="Track And Field"> | [Track And Field](sports/track_and_field) | 4 Olympic events: sprint, long jump, hurdles, hammer |
| <img src="sports/ski_jump/screen.png" width="160" height="120" alt="Ski Jump"> | [Ski Jump](sports/ski_jump) | 3-phase ski jump — crouch, fly, land |
| <img src="sports/boxing_ring/screen.png" width="160" height="120" alt="Boxing Ring"> | [Boxing Ring](sports/boxing_ring) | 3-round boxing — jab, hook, block, CPU opponent |
| <img src="sports/golf_classic/screen.png" width="160" height="120" alt="Golf Classic"> | [Golf Classic](sports/golf_classic) | 9-hole golf with wind, water, bunkers, trees |
| <img src="sports/drift_racing/screen.png" width="160" height="120" alt="Drift Racing"> | [Drift Racing](sports/drift_racing) | Top-down drift racing with physics |
| <img src="sports/fishing/screen.png" width="160" height="120" alt="Fishing"> | [Fishing](sports/fishing) | Fishing minigame with rod physics |
| <img src="sports/pinball/screen.png" width="160" height="120" alt="Pinball"> | [Pinball](sports/pinball) | Classic pinball machine |
| <img src="sports/rhythm_game/screen.png" width="160" height="120" alt="Rhythm Game"> | [Rhythm Game](sports/rhythm_game) | Musical rhythm note matching |
| <img src="sports/trajectory_sports/screen.png" width="160" height="120" alt="Trajectory Sports"> | [Trajectory Sports](sports/trajectory_sports) | Trajectory-based sports game |
| <img src="sports/sports_manager/screen.png" width="160" height="120" alt="Sports Manager"> | [Sports Manager](sports/sports_manager) | Sports team management sim |

## Action / Platformer

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="action/platformer/screen.png" width="160" height="120" alt="Platformer"> | [Platformer](action/platformer) | Side-scrolling character controller |
| <img src="action/metroidvania/screen.png" width="160" height="120" alt="Metroidvania"> | [Metroidvania](action/metroidvania) | Exploration platformer with locked areas |
| <img src="action/bullet_hell/screen.png" width="160" height="120" alt="Bullet Hell"> | [Bullet Hell](action/bullet_hell) | Bullet-hell shoot-em-up |
| <img src="action/horde_survivor/screen.png" width="160" height="120" alt="Horde Survivor"> | [Horde Survivor](action/horde_survivor) | Vampire Survivors-style horde defense |
| <img src="action/roguelite/screen.png" width="160" height="120" alt="Roguelite"> | [Roguelite](action/roguelite) | Action roguelite with procedural runs |
| <img src="action/soulslike/screen.png" width="160" height="120" alt="Soulslike"> | [Soulslike](action/soulslike) | Stamina-based combat action game |
| <img src="action/fighting_game/screen.png" width="160" height="120" alt="Fighting Game"> | [Fighting Game](action/fighting_game) | 2-player fighting game |
| <img src="action/platform_fighter/screen.png" width="160" height="120" alt="Platform Fighter"> | [Platform Fighter](action/platform_fighter) | Smash-style platform fighting |
| <img src="action/vertical_climber/screen.png" width="160" height="120" alt="Vertical Climber"> | [Vertical Climber](action/vertical_climber) | Vertical climbing platformer |
| <img src="action/stealth/screen.png" width="160" height="120" alt="Stealth"> | [Stealth](action/stealth) | Stealth infiltration game |
| <img src="action/infiltration/screen.png" width="160" height="120" alt="Infiltration"> | [Infiltration](action/infiltration) | Stealth infiltration game (alternate) |
| <img src="action/sniper/screen.png" width="160" height="120" alt="Sniper"> | [Sniper](action/sniper) | Precision sniping stealth game |
| <img src="action/endless_runner/screen.png" width="160" height="120" alt="Endless Runner"> | [Endless Runner](action/endless_runner) | Auto-scrolling obstacle runner |
| <img src="action/brick_breaker/screen.png" width="160" height="120" alt="Brick Breaker"> | [Brick Breaker](action/brick_breaker) | Breakout-style brick-breaking game |

## Strategy / Puzzle

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="strategy/physics_puzzle/screen.png" width="160" height="120" alt="Physics Puzzle"> | [Physics Puzzle](strategy/physics_puzzle) | Physics-based puzzle game |
| <img src="strategy/bridge_builder/screen.png" width="160" height="120" alt="Bridge Builder"> | [Bridge Builder](strategy/bridge_builder) | Structural bridge building puzzle |
| <img src="strategy/logic_game/screen.png" width="160" height="120" alt="Logic Game"> | [Logic Game](strategy/logic_game) | Logic circuit puzzle game |
| <img src="strategy/match3/screen.png" width="160" height="120" alt="Match3"> | [Match3](strategy/match3) | Match-3 gem swapping puzzle |
| <img src="strategy/maze_defense/screen.png" width="160" height="120" alt="Maze Defense"> | [Maze Defense](strategy/maze_defense) | Maze-building tower defense |
| <img src="strategy/hex_strategy/screen.png" width="160" height="120" alt="Hex Strategy"> | [Hex Strategy](strategy/hex_strategy) | Hex-grid turn-based strategy |
| <img src="strategy/tactical_battle/screen.png" width="160" height="120" alt="Tactical Battle"> | [Tactical Battle](strategy/tactical_battle) | Grid-based tactical combat |
| <img src="strategy/wargame/screen.png" width="160" height="120" alt="Wargame"> | [Wargame](strategy/wargame) | Hex-grid military wargame |
| <img src="strategy/rts/screen.png" width="160" height="120" alt="Rts"> | [Rts](strategy/rts) | Real-time strategy base building |
| <img src="strategy/deckbuilder/screen.png" width="160" height="120" alt="Deckbuilder"> | [Deckbuilder](strategy/deckbuilder) | Roguelike deckbuilding card game |
| <img src="strategy/card_game/screen.png" width="160" height="120" alt="Card Game"> | [Card Game](strategy/card_game) | Collectible card battles |
| <img src="strategy/tower_defense/screen.png" width="160" height="120" alt="Tower Defense"> | [Tower Defense](strategy/tower_defense) | Tower placement defense game |
| <img src="strategy/party_games/screen.png" width="160" height="120" alt="Party Games"> | [Party Games](strategy/party_games) | Multi-minigame party collection |

## Simulation / Management

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="simulation/physics_demo/screen.png" width="160" height="120" alt="Physics Demo"> | [Physics Demo](simulation/physics_demo) | Rigid bodies, sensors, collisions demo |
| <img src="simulation/physics_sandbox/screen.png" width="160" height="120" alt="Physics Sandbox"> | [Physics Sandbox](simulation/physics_sandbox) | Interactive physics sandbox |
| <img src="simulation/colony_sim/screen.png" width="160" height="120" alt="Colony Sim"> | [Colony Sim](simulation/colony_sim) | Ant colony management sim |
| <img src="simulation/idle_game/screen.png" width="160" height="120" alt="Idle Game"> | [Idle Game](simulation/idle_game) | Incremental idle clicker |
| <img src="simulation/tycoon/screen.png" width="160" height="120" alt="Tycoon"> | [Tycoon](simulation/tycoon) | Theme park tycoon management |
| <img src="simulation/zoo_tycoon/screen.png" width="160" height="120" alt="Zoo Tycoon"> | [Zoo Tycoon](simulation/zoo_tycoon) | Zoo management tycoon |
| <img src="simulation/hotel_manager/screen.png" width="160" height="120" alt="Hotel Manager"> | [Hotel Manager](simulation/hotel_manager) | Hotel management tycoon |
| <img src="simulation/tower_sim/screen.png" width="160" height="120" alt="Tower Sim"> | [Tower Sim](simulation/tower_sim) | Corporate tower building sim |
| <img src="simulation/factory/screen.png" width="160" height="120" alt="Factory"> | [Factory](simulation/factory) | Factory automation conveyor sim |
| <img src="simulation/farming_sim/screen.png" width="160" height="120" alt="Farming Sim"> | [Farming Sim](simulation/farming_sim) | Crop planting and harvesting sim |
| <img src="simulation/mining/screen.png" width="160" height="120" alt="Mining"> | [Mining](simulation/mining) | Dig-down mining resource game |
| <img src="simulation/railroad/screen.png" width="160" height="120" alt="Railroad"> | [Railroad](simulation/railroad) | Train network railroad tycoon |
| <img src="simulation/medical_sim/screen.png" width="160" height="120" alt="Medical Sim"> | [Medical Sim](simulation/medical_sim) | Medical diagnosis triage game |
| <img src="simulation/god_game/screen.png" width="160" height="120" alt="God Game"> | [God Game](simulation/god_game) | God simulation with worshippers |
| <img src="simulation/vehicle_builder/screen.png" width="160" height="120" alt="Vehicle Builder"> | [Vehicle Builder](simulation/vehicle_builder) | Vehicle construction physics |
| <img src="simulation/cooking_sim/screen.png" width="160" height="120" alt="Cooking Sim"> | [Cooking Sim](simulation/cooking_sim) | Multi-step recipe cooking sim |
| <img src="simulation/wildlife_photo/screen.png" width="160" height="120" alt="Wildlife Photo"> | [Wildlife Photo](simulation/wildlife_photo) | Wildlife photography safari |

## RPG / Narrative

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="rpg/roguelike/screen.png" width="160" height="120" alt="Roguelike"> | [Roguelike](rpg/roguelike) | Turn-based dungeon roguelike |
| <img src="rpg/adventure/screen.png" width="160" height="120" alt="Adventure"> | [Adventure](rpg/adventure) | Point-and-click adventure game |
| <img src="rpg/creature_collector/screen.png" width="160" height="120" alt="Creature Collector"> | [Creature Collector](rpg/creature_collector) | Monster catching and battling |
| <img src="rpg/loot_rpg_demo/screen.png" width="160" height="120" alt="Loot Rpg Demo"> | [Loot Rpg Demo](rpg/loot_rpg_demo) | RPG loot and inventory demo |
| <img src="rpg/visual_novel/screen.png" width="160" height="120" alt="Visual Novel"> | [Visual Novel](rpg/visual_novel) | Visual novel story engine demo |
| <img src="rpg/dialog_demo/screen.png" width="160" height="120" alt="Dialog Demo"> | [Dialog Demo](rpg/dialog_demo) | Typewriter text and branching dialog |
| <img src="rpg/courtroom/screen.png" width="160" height="120" alt="Courtroom"> | [Courtroom](rpg/courtroom) | Courtroom debate evidence game |
| <img src="rpg/social_deduction/screen.png" width="160" height="120" alt="Social Deduction"> | [Social Deduction](rpg/social_deduction) | Among Us-style social deduction |
| <img src="rpg/alchemy/screen.png" width="160" height="120" alt="Alchemy"> | [Alchemy](rpg/alchemy) | Potion brewing with ingredient combos |
| <img src="rpg/merchant_demo/screen.png" width="160" height="120" alt="Merchant Demo"> | [Merchant Demo](rpg/merchant_demo) | Shop and trading system demo |
| <img src="rpg/horror/screen.png" width="160" height="120" alt="Horror"> | [Horror](rpg/horror) | First-person horror exploration |
| <img src="rpg/survival_crafting/screen.png" width="160" height="120" alt="Survival Crafting"> | [Survival Crafting](rpg/survival_crafting) | Survival crafting game |

## Engine Showcase

| Preview | Demo | Description |
|:-------:|------|-------------|
| <img src="showcase/hello_world/screen.png" width="160" height="120" alt="Hello World"> | [Hello World](showcase/hello_world) | Minimal game: shapes, text, keyboard |
| <img src="showcase/sprites/screen.png" width="160" height="120" alt="Sprites"> | [Sprites](showcase/sprites) | Sprite movement and mouse input |
| <img src="showcase/demo_game/screen.png" width="160" height="120" alt="Demo Game"> | [Demo Game](showcase/demo_game) | Complete shooting gallery game |
| <img src="showcase/particles_demo/screen.png" width="160" height="120" alt="Particles Demo"> | [Particles Demo](showcase/particles_demo) | Particle emitter systems showcase |
| <img src="showcase/scene_demo/screen.png" width="160" height="120" alt="Scene Demo"> | [Scene Demo](showcase/scene_demo) | Multi-screen state machine demo |
| <img src="showcase/pipeline_showcase/screen.png" width="160" height="120" alt="Pipeline Showcase"> | [Pipeline Showcase](showcase/pipeline_showcase) | Full pipeline: ready · process · process_physics · process_late · render · render_ui — with scene stack, ECS entities and GUI |
| <img src="showcase/entity_showcase/screen.png" width="160" height="120" alt="Entity Showcase"> | [Entity Showcase](showcase/entity_showcase) | Complete tour of every `lurek.entity` Universe method: lifecycle, components, tags, bitmap tags, layers, hierarchy, blueprints, systems |
| <img src="showcase/tween_demo/screen.png" width="160" height="120" alt="Tween Demo"> | [Tween Demo](showcase/tween_demo) | All easing curves side-by-side |
| <img src="showcase/signal_demo/screen.png" width="160" height="120" alt="Signal Demo"> | [Signal Demo](showcase/signal_demo) | Pub-sub event bus demo |
| <img src="showcase/patterns_demo/screen.png" width="160" height="120" alt="Patterns Demo"> | [Patterns Demo](showcase/patterns_demo) | 6 game design patterns in Lua |
| <img src="showcase/minimap_demo/screen.png" width="160" height="120" alt="Minimap Demo"> | [Minimap Demo](showcase/minimap_demo) | Fog-of-war overhead minimap demo |
| <img src="showcase/nine_slice_demo/screen.png" width="160" height="120" alt="Nine Slice Demo"> | [Nine Slice Demo](showcase/nine_slice_demo) | Scalable 9-patch UI panels demo |
| <img src="showcase/overlay_demo/screen.png" width="160" height="120" alt="Overlay Demo"> | [Overlay Demo](showcase/overlay_demo) | Z-ordered render layers demo |
| <img src="showcase/postfx_demo/screen.png" width="160" height="120" alt="Postfx Demo"> | [Postfx Demo](showcase/postfx_demo) | Post-processing effects stack |
| <img src="showcase/localization_demo/screen.png" width="160" height="120" alt="Localization Demo"> | [Localization Demo](showcase/localization_demo) | Multi-language string system demo |
| <img src="showcase/light_demo/screen.png" width="160" height="120" alt="Light Demo"> | [Light Demo](showcase/light_demo) | 2D dynamic lighting demo |
| <img src="showcase/light_showcase/screen.png" width="160" height="120" alt="Light Showcase"> | [Light Showcase](showcase/light_showcase) | Advanced lighting effects gallery |
| <img src="showcase/terminal_demo/screen.png" width="160" height="120" alt="Terminal Demo"> | [Terminal Demo](showcase/terminal_demo) | In-game developer terminal |
| <img src="showcase/automation_demo/screen.png" width="160" height="120" alt="Automation Demo"> | [Automation Demo](showcase/automation_demo) | Automated input replay demo |
| <img src="showcase/debugbridge_demo/screen.png" width="160" height="120" alt="Debugbridge Demo"> | [Debugbridge Demo](showcase/debugbridge_demo) | TCP debug server (JSON-RPC) demo |
| <img src="showcase/devtools_demo/screen.png" width="160" height="120" alt="Devtools Demo"> | [Devtools Demo](showcase/devtools_demo) | Runtime diagnostics overlay |
| <img src="showcase/docs_demo/screen.png" width="160" height="120" alt="Docs Demo"> | [Docs Demo](showcase/docs_demo) | In-game API browser |
| <img src="showcase/modding_demo/screen.png" width="160" height="120" alt="Modding Demo"> | [Modding Demo](showcase/modding_demo) | Mod discovery and loading demo |
| <img src="showcase/province_demo/screen.png" width="160" height="120" alt="Province Demo"> | [Province Demo](showcase/province_demo) | Province map strategy demo |
| <img src="showcase/hacking_game/screen.png" width="160" height="120" alt="Hacking Game"> | [Hacking Game](showcase/hacking_game) | Network-hacking puzzle game |
| <img src="showcase/music_composer/screen.png" width="160" height="120" alt="Music Composer"> | [Music Composer](showcase/music_composer) | Music sequencer and composer |

---

## See Also

- [`examples/`](../examples/) — API reference code (one `.lua` file per module)
- [`library/`](../library/) — Reusable pure-Lua gameplay libraries
- [Getting Started](../docs/getting_started.md) — Build your first game with Lurek2D
