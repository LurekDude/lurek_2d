# Merchant Demo

A shop / trading simulation showing how `lurek.item` and `lurek.inventory` combine to build a merchant storefront with stock management, a player purse, and a sales ledger.

## What It Shows

- **Item catalog with prices** — `lurek.item.defineType` with `price`, `dmg`, `def`, `hp` base stats
- **Merchant shelf** — Stock organised in a `lurek.item.newStackManager` keyed by category
- **Player purse** — Coin tracking and affordability checks
- **Purchase bag** — A `lurek.inventory.newContainer` for bought items
- **Group-by-category view** — Rendering grouped shelf rows
- **Auto-buy** — `findNOfStat` picks the most valuable item the player can afford
- **Sales ledger** — Every transaction recorded in a `lurek.item.newHistory`

## Controls

| Key | Action |
|-----|--------|
| **1–6** | Buy the corresponding shelf item |
| **A** | Auto-buy the most valuable affordable item |
| **S** | Print sales ledger summary to console (`RUST_LOG=debug`) |
| **R** | Restock the merchant |

## Run

```sh
cargo run -- content/demos/merchant_demo
```
