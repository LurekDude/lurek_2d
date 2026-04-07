# Idle Game

A classic incremental clicker with passive generators, one-time upgrades, and a prestige reset loop. Click the large coin button to earn manually, buy generators that produce coins per second, and purchase upgrades that multiply click power or generator output. Prestiging at 10 000 lifetime coins resets progress but doubles all future earnings.

## What It Demonstrates

- `luna.mousepressed()` — big-button click detection and shop-panel interaction
- `luna.keyboard.wasPressed()` — escape to quit
- `luna.graphics.circle()` — animated pulsing coin button with `math.sin()` scale oscillation
- `luna.graphics.rectangle()` — generator and upgrade purchase panels with cost and count labels
- `luna.graphics.print()` — large coin counter, CPS display, and floating click-particle text
- `luna.graphics.setColor()` — affordability tinting (grey = can't afford, gold = available)
- `luna.graphics.setBackgroundColor()` — dark purple background set each draw frame
- Number formatter — `format_num()` abbreviates large values to K / M / B suffixes

## How to Run

```powershell
cargo run -- demos/idle_game
```

## Controls

| Input | Action |
|-------|--------|
| Left Click (big button) | Earn coins manually |
| Left Click (generator row) | Buy a generator if affordable |
| Left Click (upgrade row) | Buy an upgrade if affordable and not yet owned |
| Left Click (Prestige button) | Reset and gain a permanent 2× multiplier (requires 10 000 lifetime coins) |
| Escape | Quit |

## Notes

- Generator costs follow `base_cost × 1.15^count`, creating an exponential price curve
- The prestige multiplier stacks as `2^prestige_count`, so each prestige doubles lifetime output
- Click particles use a simple life-timer list; dead particles are removed via a filtered rebuild each frame
- `get_cps()` sums all generator contributions and applies `prestige_mult`, making it the single source of truth for automation income
