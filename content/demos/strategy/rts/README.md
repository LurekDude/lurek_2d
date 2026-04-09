# Real-Time Strategy

A top-down real-time strategy game with two factions. Build workers to harvest gold from resource nodes, train soldiers to attack the enemy base, and automate your economy while fending off the AI opponent. Destroy the enemy base to win.

## What It Demonstrates

- Entity-component tables: every `unit` and `building` is a plain Lua table with `id`, `team`, `kind`, `hp`, `x/y` fields
- Harvesting loop: workers move to resource nodes, wait, then return gold to base with a carrying cap
- Selection and command pattern: left-click selects from `units[]`, right-click issues move/attack orders
- Basic AI loop driven by an `aiTimer` accumulator: the enemy AI periodically builds units and attacks
- Range-based attack: units check `dist(u, target) < u.range` each frame and fire if cooldown allows
- Building destruction victory condition: `hp <= 0` on the enemy base triggers the win state

## How to Run

```powershell
cargo run -- content/demos/rts
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click unit | Select unit (Shift to add to selection) |
| Right Click ground | Move selected units to position |
| Right Click enemy | Attack-move selected units to enemy |
| `B` | Build worker ($15) at player base |
| `S` | Build soldier ($30) at player base |
| `Escape` | Quit |

## Notes

- Workers harvest automatically once sent to a resource node (right-click).
- Resource nodes deplete over time; spread workers across multiple nodes for sustained income.
- The AI builds workers and soldiers on a timer — act quickly before it outnumbers you.
