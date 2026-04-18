# Card Game

**Category:** strategy

Turn-based strategic card battle game. Build a hand of creatures and spells, manage mana, deploy units to the battlefield, and defeat the AI opponent by reducing their HP to zero.

## Run

```
cargo run -- content/games/strategy/card_game
```

## Controls

| Key         | Action               |
| ----------- | -------------------- |
| Mouse click | Select card / target |
| Space       | End turn             |
| Escape      | Quit                 |

## Mechanics

- **Players**: You (bottom row) vs AI (top row). Each starts with 20 HP, 3 mana, a 20-card deck, and a hand of 5 cards.
- **Mana**: Increases by 1 each turn (max 10). Spent to play cards.
- **Creatures**: Placed on the field (max 5 per side). Attack once per turn — target enemy creatures or the enemy player. Combat is simultaneous: both attacker and defender deal damage to each other.
- **Taunt**: Golem has taunt — must be attacked first if present.
- **Spells**: Instant effects (Fireball deals 3 damage, Heal restores 5 HP, Shield gives +0/+3).
- **Turn flow**: Draw 1 card → play cards → attack with creatures → end turn.
- **AI**: Plays highest-cost affordable card, attacks strongest player creature first.
- **Win/Lose**: Reduce enemy HP to 0 to win. Your HP reaches 0, you lose.

## Card List

| Card     | Type     | Cost | Stats             |
| -------- | -------- | ---- | ----------------- |
| Soldier  | Creature | 1    | 2/1               |
| Wolf     | Creature | 2    | 3/2               |
| Knight   | Creature | 3    | 3/4               |
| Golem    | Creature | 5    | 2/8 (taunt)       |
| Phoenix  | Creature | 6    | 4/4 (revive)      |
| Dragon   | Creature | 7    | 6/5               |
| Shield   | Spell    | 1    | +0/+3 to creature |
| Heal     | Spell    | 2    | +5 HP to player   |
| Fireball | Spell    | 3    | 3 damage          |

## Features

- Two-row battlefield with creature slots and health bars
- Hand of cards displayed at bottom with cost/stats overlay
- Mana crystals, HP bars, and turn indicator in HUD
- Particle effects for card play, damage, death, and fireball
- Tween animations for card draw, damage shake, mana fill, and HP drain
- AI opponent with basic strategic decision-making
- Title screen and game-over screen with restart

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.timer`, `lurek.event`
