# Sports Manager

**Category:** Sports
**Engine:** Lurek2D

## Description

A team sports management simulation where you guide a soccer club through a 14-week league season. Scout talent on the transfer market, train your squad between matches, set your starting eleven, and watch automated match simulations with play-by-play commentary. Finish in the top 3 to win the league.

## How to Play

- **R** — open roster view; click a player to toggle starter / bench
- **T** — open training screen between matches
  - **O** — train Offense (+2 skill to attackers)
  - **D** — train Defense (+2 skill to defenders)
  - **F** — train Fitness (+5 stamina to all)
  - **M** — train Morale (+10 morale to all)
- **B** — open transfer market to buy new players
- **1–4** — select a player on the market to purchase
- **Space** — advance to the next match
- **Enter** — confirm / start from title screen
- **Escape** — quit

## Goals

- Play a full 14-match-week round-robin season
- Finish in the **top 3** of the 8-team league to win

## Features

- 11-player squad with generated names, skill, stamina, and morale stats
- Automated 5-second match simulation with goal, save, red card, and injury events
- 8-team round-robin league with full standings table
- Training system with four focus areas between matches
- Transfer market refreshing each week with budget management
- Stamina depletion and injury system affecting availability
- Goal celebration, training sweat, and transfer sparkle particles
- Tween animations for score counters, league table shifts, and morale bars
- Title screen, office hub, and season-end summary

## Running

```bash
cargo run -- content/games/sports/sports_manager
```
