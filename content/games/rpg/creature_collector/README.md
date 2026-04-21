# Creature Collector

_Pokemon-style creature collection RPG with tile-based overworld, turn-based battles, type advantages, and party management._

## Run

```powershell
cargo run -- content/games/rpg/creature_collector
```

## Controls

| Input  | Action                        |
| ------ | ----------------------------- |
| W / ↑  | Move up                       |
| A / ←  | Move left                     |
| S / ↓  | Move down                     |
| D / →  | Move right                    |
| 1      | Fight / Select move 1 / Start |
| 2      | Catch / Select move 2         |
| 3      | Switch creature               |
| 4      | Run from battle               |
| Escape | Quit                          |

## Gameplay

Explore a 25×18 tile-based overworld with grass, water, trees, paths, and a healing spot. Walking on grass tiles has a 10% chance per step to trigger a wild creature encounter.

**Type System** — Three types form a rock-paper-scissors triangle: Fire beats Grass, Grass beats Water, Water beats Fire. Super-effective moves deal 1.5× damage.

**Catching** — Lower the wild creature's HP for a higher catch rate: 30% base, 40% at half HP, 70% at quarter HP. Caught creatures join your party (up to 3).

**Turn-Based Battles** — Choose Fight (pick one of two moves), Catch, Switch active creature, or Run. Damage formula: `(ATK × move_power / DEF) × type_bonus`. Defeat a creature or catch it to earn XP.

**Party & Levels** — Start with one random starter at Lv.3. Earn XP from battles to level up, which increases HP, ATK, and DEF. Visit the healing spot (red cross tile) to restore all party HP.

**Win Condition** — Catch all 6 species: Flamepup, Aquafin, Leafling, Emberclaw, Tidalink, and Thornvine.

## Creature Species

| Name      | Type  | Moves                 |
| --------- | ----- | --------------------- |
| Flamepup  | Fire  | Ember, Fire Fang      |
| Aquafin   | Water | Splash, Tidal Crash   |
| Leafling  | Grass | Vine Whip, Leaf Storm |
| Emberclaw | Fire  | Scratch, Blaze Rush   |
| Tidalink  | Water | Bubble, Aqua Jet      |
| Thornvine | Grass | Thorn Jab, Root Slam  |

## APIs Used

**`lurek.*` engine bindings**

- `lurek.render` — tile-based map rendering, creature circles, battle scene, HUD overlays.
- `lurek.input` — action-bound WASD movement and number key battle choices.
- `lurek.window` — dynamic title with FPS counter.
- `lurek.camera` — follows player on the overworld, resets for UI.
- `lurek.timer` — FPS counter and delta time.
- `lurek.event` — clean shutdown on Escape.

**Visual effects (pure Lua)**

- Particles — battle start flash, type-effective bursts (fire/water/grass themed), catch sparkles, level-up glow.
- Tweens — HP bar drain animation, damage popup float.
- Screen shake — on battle start and super-effective hits.
