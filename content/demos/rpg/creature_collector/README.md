# Creature Collector

A Pokémon-inspired RPG demo with overworld exploration and turn-based battles. Walk through a procedurally generated tile map, trigger random encounters in tall grass, and battle wild creatures using type-advantage multipliers. Catch defeated creatures to grow your party.

## What It Demonstrates

- `luna.gfx.rectangle()` — tile map rendering with per-tile colour coding
- `luna.gfx.circle()` — creature sprites and player avatar on the overworld
- `luna.gfx.print()` — battle log, HP values, party summary HUD
- `luna.gfx.setColor()` — type-coloured creature indicators and HP bar gradient
- `luna.keyboard.isDown()` — grid-based WASD movement with cooldown gating
- `luna.keyboard.isPressed()` — battle menu navigation (1=attack, 2=switch, 3=catch, 4=run)
- `luna.gfx.setBackgroundColor()` — distinct overworld vs. battle scene backgrounds

## How to Run

```powershell
cargo run -- demos/creature_collector
```

## Controls

| Input | Action |
|-------|--------|
| WASD | Move on the overworld (one tile per step) |
| 1 | Attack with active party creature |
| 2 | Switch to next party creature |
| 3 | Attempt to catch the wild creature |
| 4 | Flee the battle |

## Notes

- Encounters trigger after every 10 steps taken on tall-grass tiles; the counter resets on each encounter.
- Type advantages (fire > grass > water > fire) apply a ×1.5 / ×0.6 damage multiplier.
- Wild creature level scales randomly 1–3; higher levels have proportionally more HP, attack, and defence.
- Caught creatures join your party and can be switched in during future battles.
