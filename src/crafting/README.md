# `src/crafting/` — Crafting System

## Purpose

Recipe-based item crafting with ingredients, crafting stations, output quality
tiers, skill progression, and an asynchronous craft queue.

## Contents

| Type | Purpose |
|------|---------|
| `Quality` | Output quality tiers (Normal → Legendary) |
| `Ingredient` | Recipe input — item kind, amount, consumed flag |
| `Recipe` | Named formula with ingredients, outputs, time, station, skill req |
| `CraftingStation` | Station with skill bonus, queue, and active status |
| `CraftQueue` | Asynchronous job queue with progress and callbacks |

## Tier

**Tier 3** (gameplay-specific). Must not be imported by Tier 1 or Tier 2 modules.
