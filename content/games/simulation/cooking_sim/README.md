# Cooking Sim

Kitchen cooking simulation where you prep ingredients, cook dishes, and serve customers under time pressure.

## Run

```
cargo run -- content/games/simulation/cooking_sim
```

## Controls

| Key          | Action                           |
| ------------ | -------------------------------- |
| Left / Right | Move between stations            |
| Up / Down    | Browse inventory                 |
| Enter        | Place ingredient at Prep Station |
| Space        | Action (prep / collect / serve)  |
| Escape       | Quit                             |

## Gameplay

Manage a kitchen with four stations — Prep Station, Stove, Oven, and Serving Counter. Combine ingredients into recipes, cook them at the right station, and serve customers before their patience runs out. Each day lasts 120 seconds. Earn gold by fulfilling orders correctly and keep satisfaction above zero to survive.

### Stations

- **Prep Station** — place up to 3 ingredients, then press Space to prep a matching recipe
- **Stove** — cooks burgers in 5 seconds; collect before it burns (+3s overcook window)
- **Oven** — bakes pizza in 8 seconds; same overcook rule
- **Serving Counter** — serve the completed dish to the first customer in the queue

### Recipes

| Dish     | Ingredients               | Cooking              | Price   |
| -------- | ------------------------- | -------------------- | ------- |
| Sandwich | bread + meat + lettuce    | Prep → Serve         | 15 gold |
| Pizza    | bread + cheese + tomato   | Prep → Oven → Serve  | 25 gold |
| Burger   | bread + meat + cheese     | Prep → Stove → Serve | 20 gold |
| Salad    | tomato + lettuce + cheese | Prep → Serve         | 10 gold |

### Day Cycle

- 120-second days with a visible countdown bar
- 3 customers in queue, each with a 30-second patience timer
- End of day: spend 5 gold to buy an ingredient restock pack
- Game over when satisfaction drops to 0%
