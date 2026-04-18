# Dialog Demo

**Category:** RPG  
**Engine:** Lurek2D

A complete dialog/conversation system with typewriter text display, branching choices, and multiple characters across three distinct scenes.

## How to Play

- **Space** — Advance dialog
- **1/2/3** — Select dialog choice
- **Tab** — Toggle auto-advance mode (2s delay)
- **S** — Skip typewriter, show full line instantly
- **Escape** — Quit

## Mechanics

- **Inline Dialog Sequencer** — Node-based system with say, choice, wait, and event nodes (no external library)
- **Typewriter Effect** — Text appears at 25 characters per second with skip support
- **3 Characters** — Sage (wise mentor, blue), Merchant (trader, gold), Guard (suspicious, red)
- **Branching Paths** — Choices affect relationship values and unlock different dialog branches
- **Dialog Log** — Last 8 lines of conversation displayed on screen
- **Background Scenes** — Forest, shop, and gate scenes change per conversation
- **Auto-Advance** — Tab toggles automatic 2-second advance between lines
- **Event System** — Choices trigger callbacks that modify relationship values and unlock branches

## Characters

1. **Sage** — A wise mentor in the forest who offers guidance on two topics
2. **Merchant** — A trader in the shop with items to barter over
3. **Guard** — A suspicious gate keeper who can be talked down or challenged

## Running

```bash
cargo run -- content/games/rpg/dialog_demo
```
