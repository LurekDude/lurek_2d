# Courtroom Drama

**Category:** RPG  
**Engine:** Lurek2D

An Ace Attorney-inspired courtroom debate game where you cross-examine witnesses, present evidence, and convince the jury.

## How to Play

- **Space** — Advance dialogue / testimony
- **O** — Shout OBJECTION! during testimony (select evidence to back it up)
- **E** — Toggle evidence panel
- **Q** — Question the witness (choose question type with 1/2/3)
- **1/2/3** — Select choices during questioning or evidence selection
- **Escape** — Quit

## Mechanics

- **3 Court Cases** of increasing complexity — solve all three to win
- **Testimony System** — Witnesses deliver testimony line by line; find the contradiction
- **Evidence Panel** — Collected evidence items you can present during objections
- **OBJECTION!** — Object at the right moment with the right evidence to break testimony
- **Jury Meter** — Fill to 100 by making correct objections (+25 each)
- **Credibility** — Starts at 100; wrong objections cost -20. Reach 0 and you lose the case
- **Typewriter Text** — All dialogue displays with a dramatic typewriter effect

## Cases

1. **The Missing Diamond** — A guard's alibi is contradicted by security footage
2. **The Poisoned Cake** — A chef's testimony doesn't match the receipt
3. **Corporate Espionage** — A CEO's timeline conflicts with email logs

## Running

```bash
cargo run -- content/games/rpg/courtroom
```
