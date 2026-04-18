# Merchant

Medieval trading shop simulation where you buy low, sell high, and manage your inventory to maximize profit over a five-day cycle.

## Run

```
cargo run -- content/games/rpg/merchant
```

## Controls

| Key | Action |
|-----|--------|
| 1–8 | Buy item / sell item (in sell mode) |
| A | Auto-buy most expensive affordable item |
| S | Toggle sell mode |
| R | Restock merchant shelf |
| L | Open/close sales ledger |
| Escape | Quit |

## Mechanics

- **Item catalog**: 8 items across Weapons, Armor, and Potions — each with unique gold cost and stats.
- **Trading**: Buy items from the merchant shelf and hold them in your inventory. Sell back at 75% of buy price, or wait for customers offering 120%.
- **Customers**: A customer arrives every 5 seconds wanting a random item. If you have it in stock, you auto-sell at a premium. Refusing too many customers lowers your reputation.
- **Reputation**: Successful sales raise your reputation, which increases sell prices over time. Missing customer requests lowers it.
- **Daily cycle**: Each day lasts 60 seconds. After 5 days the game ends and your final gold is your score.
- **Sales ledger**: Press L to review a log of all buy/sell transactions.
