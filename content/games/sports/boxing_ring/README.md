# Boxing Ring

Side-view boxing game with a full 3-round fight system, stamina management, combo tracking, and an AI opponent that gets tougher each round.

## Run

```
cargo run -- content/games/sports/boxing_ring
```

## Controls

| Key    | Action                       |
| ------ | ---------------------------- |
| A / D  | Move left / right            |
| W      | Duck (dodges jabs and hooks) |
| S      | Lean back (dodges uppercuts) |
| J      | Jab (fast, 5 dmg)            |
| K      | Hook (medium, 10 dmg)        |
| L      | Uppercut (slow, 20 dmg)      |
| Space  | Block (80% damage reduction) |
| Escape | Quit                         |

## Gameplay

Step into the ring for a 3-round boxing match. Each round lasts 60 seconds. Manage your stamina — every punch costs energy, and running dry leaves you slow and unable to attack. Land consecutive hits to build combos for bonus score. Between rounds both fighters recover 20% HP. Win by knockout (reduce opponent HP to 0) or by dealing more total damage over three rounds.

### Attack Types
- **Jab** — fast, 5 damage, short range, 0.2s cooldown, costs 5 stamina
- **Hook** — medium speed, 10 damage, medium range, 0.5s cooldown, costs 10 stamina
- **Uppercut** — slow, 20 damage, close range only, 1.0s cooldown, costs 20 stamina

### Dodge Mechanics
- **Duck (W)** — avoids jabs and hooks at head height
- **Lean back (S)** — avoids uppercuts from below

### AI Opponent
The AI cycles through idle, approach, attack, retreat, and block states. Difficulty increases each round with faster reactions, more frequent attacks, and better blocking.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `isActionDown` / `wasActionPressed`)

### Added
- Title screen with fight card, game over screen with final scores
- Particle effects (punch impact sparks, sweat drops, KO stars)
- Tween animations (HP bar drain, hit stagger, round transition banner)
- `render` / `render_ui` split with HUD overlay (HP bars, stamina bars, round info, score, FPS)
- Camera centered on ring
- 3-round system with between-round HP recovery and difficulty scaling
