# Loot RPG Demo

A dungeon-crawler-style item and inventory example that shows how `luna.item` and `luna.inventory` integrate to power an RPG gear system.

## What It Shows

- **Item catalog** — Defining typed items with stats and tags via `luna.item.defineType`
- **Loot pool** — Weighted random drops from a `luna.item.newItemPool`
- **Gear builder** — Auto-equipping highest-stat gear with `luna.item.newStackBuilder`
- **Pickup journal** — Logging every drop with `luna.item.newHistory`
- **Weight-limited backpack** — A weight-capped `luna.inventory.newContainer`
- **Equipment slots** — Six named slots (weapon, offhand, head, body, legs, boots) via `luna.inventory.newInventory`
- **Shop with StackManager** — Buying potions with coins via `luna.item.newStackManager`

## Controls

| Key | Action |
|-----|--------|
| **Space** | Clear a new dungeon room (rolls a new loot drop) |
| **E** | Auto-equip the best gear from the backpack |
| **B** | Buy 1 potion from the shop (costs 5 coins) |
| **H** | Cheat — gain +50 HP via a free potion |

## Run

```sh
cargo run -- examples/loot_rpg_demo
```
