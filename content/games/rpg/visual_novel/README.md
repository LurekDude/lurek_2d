# Visual Novel — Lurek2D

A branching visual novel with three acts, three characters, affection tracking, and multiple endings.

## Run

```
cargo run -- content/games/rpg/visual_novel
```

## Controls

| Key       | Action                         |
| --------- | ------------------------------ |
| Space     | Advance dialog                 |
| 1 / 2 / 3 | Select choice option           |
| S         | Skip to next choice            |
| Tab       | Toggle auto-advance (3s delay) |
| H         | Toggle dialog history log      |
| Escape    | Quit                           |

## Characters

| Name | Color | Position | Personality                                |
| ---- | ----- | -------- | ------------------------------------------ |
| Luna | Blue  | Left     | Shy librarian who loves ancient texts      |
| Sol  | Gold  | Center   | Confident adventurer seeking glory         |
| Nova | Pink  | Right    | Mysterious scientist researching anomalies |

## Story Structure

- **Act 1 — Arrivals**: Meet all three characters at the Academy. Establish relationships through dialog choices.
- **Act 2 — The Crisis**: A strange energy surge threatens the Academy. Choose which character to help — a major branch point.
- **Act 3 — Resolution**: Outcome depends on which character has the highest affection score.

## Endings

| Ending | Condition                  | Theme                                                             |
| ------ | -------------------------- | ----------------------------------------------------------------- |
| Luna   | Luna has highest affection | Library peace — you stay and help catalog the ancient archives    |
| Sol    | Sol has highest affection  | Adventure — you set out together to explore uncharted lands       |
| Nova   | Nova has highest affection | Discovery — you join her research team and uncover a breakthrough |

## Affection System

- Each choice awards +10 to +20 affection to one character.
- Some choices reduce another character's affection by -5.
- Final ending is determined by the character with the highest affection after Act 2.

## Features

- Typewriter text display (0.03s per character)
- Character portraits with colored name labels
- Scene backgrounds change per narrative beat
- Particle effects on scene transitions and choice selection
- Tween animations for character entrances and text fades
- Skip mode and auto-advance for replay convenience
- Dialog history overlay (last 10 lines)
