# src/dialog/

Dialog sequencer for visual-novel-style text presentation.

## What This Module Contains

Single-file module (`mod.rs`). DialogSequencer is a state machine driven by
a flat Vec of DialogNode values. Supports Say (speaker + text with typewriter),
Choice (branching), Wait (pause), and Call (Lua callback index) nodes.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | DialogNode, ChoiceOption, DialogSequencer |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/dialog_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- No dependencies on other domain modules
- May import `math` and `engine` only
