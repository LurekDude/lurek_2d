# Fishing

**Category:** Sports
**Engine:** Lurek2D

## Description

A relaxing side-view fishing game. Cast your line into the lake, wait for a bite, then reel in your catch through a tug-of-war tension minigame. Five fish species range from common Minnows to the legendary Golden Fish. Choose your bait wisely, watch the day/night cycle, and fill your bucket before the session ends.

## How to Play

- **Hold Space** — charge casting power, release to cast
- **Space** — hook a biting fish / reel in during the catching minigame
- **1 / 2 / 3** — switch bait (Worm / Fly / Deep Bait)
- **Escape** — quit

## Goals

- Catch **10 fish** to win, OR
- Land the **Golden Fish** (legendary, 5% spawn chance) for an instant victory

## Features

- Five fish species with unique rarity, point values, and fight difficulty
- Casting power bar with distance-based line physics
- Tug-of-war reeling minigame with tension management
- Three bait types that attract different species
- Day/night cycle (120s) — rare fish are more common at night
- Dynamic weather (rain) that increases bite frequency
- Water splash, rain, bobber ripple, and catch sparkle particles
- Smooth tween animations for bobber, tension bar, and fish movement
- Title screen, bucket view, and game-over summary

## Running

```bash
cargo run -- content/games/sports/fishing
```
