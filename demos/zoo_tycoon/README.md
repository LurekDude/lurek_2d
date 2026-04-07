# Zoo Tycoon

A top-down zoo management simulation on a 20 × 15 grid. Build paths, fences, and facilities; place animals into their enclosures; and attract guests to earn daily ticket revenue. Guest happiness and animal welfare drive your income — a poorly designed zoo generates less revenue each day.

## What It Demonstrates

- Grid-based tile system with seven cell types: grass, path, fence, water, tree, food_stand, gift_shop
- Animal placement with habitat requirements: lions and monkeys need tree tiles, penguins and elephants need water tiles
- Guest AI state machine: guests enter at the gate, walk toward animals they find attractive, spend money at food stands and gift shops, then leave
- Daily revenue cycle: `DAY_LENGTH = 30` seconds tallies ticket income (`TICKET_PRICE × guests`), food stand revenue, and animal upkeep costs
- Happiness system: `happiness` rises when guests are near attractive animals and falls when needs are unmet
- Tool-cost economy: each build action deducts from `gold`; removing tiles refunds nothing
- Daily report screen: end-of-day revenue, costs, and net profit displayed before the next day begins

## How to Run

```powershell
cargo run -- demos/zoo_tycoon
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click grid (build mode) | Place selected tile |
| `1` – `7` | Select tool: path / fence / water / tree / food stand / gift shop / remove |
| `1` – `4` (animal mode) | Select animal: Lion / Penguin / Monkey / Elephant |
| `A` | Toggle animal placement mode |
| `Enter` | Advance to next day in report screen |
| `Escape` | Quit |

## Notes

- Build fence tiles around an animal to form an enclosure; animals outside fenced areas reduce happiness.
- Food stands and gift shops generate passive revenue each day, independent of guest visits.
- Elephants are the most attractive animal (`attract = 20`) but also the most expensive to feed (`food_cost = 12`).
