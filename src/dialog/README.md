# `src/dialog/` — Dialog Sequencer

## Purpose

Visual-novel-style dialog sequencer with typewriter effect, branching choices,
timed pauses, and inline Lua callbacks. Drives text-based narrative sequences
from flat script arrays.

## Contents

| Type | Purpose |
|------|---------|
| `DialogNode` | Script node: Say / Choice / Wait / Call |
| `ChoiceOption` | Branch option with label and sub-nodes |
| `DialogSequencer` | State machine driving a node array with typewriter effect |

## Tier

**Tier 2** (generic extension — not genre-specific). May import from Tier 1 only.
