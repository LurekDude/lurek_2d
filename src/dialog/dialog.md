# luna.dialog — Dialog Sequencer

> **Luna2D-specific module** — This module is specific to Luna2D.

## Purpose

A dialog/conversation sequencer for visual novel-style text presentation with typewriter effect, branching choices, timed pauses, and inline callbacks. Drives text-based narrative sequences.

## Reimplementation Notes

- **Recommended strategy**: **Pure Lua** — one type (Sequencer), pure state machine, no GPU/audio/threading
- Typewriter effect is a simple character counter driven by `update(dt)`
- Branch nodes from choices are spliced inline into the flat node array
- One callback per event slot (not multi-listener)

---

## Module-Level Functions (`luna.dialog.*`)

| Lua API | Parameters | Returns | Description |
|---|---|---|---|
| `luna.dialog.newSequencer()` | — | `Sequencer` | Create a new dialog sequencer |

---

## Type: `Sequencer`

Default typewriter speed: **30 cps** (characters per second).

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `load(script)` | `table` | — | Load script node array. Clears previous script, resets to IDLE |
| `start()` | — | — | Begin playback from node 1. If empty → DONE |
| `update(dt)` | `number` | — | Advance typewriter/wait timers. Call every frame |
| `advance()` | — | — | TYPING → completes text → WAITING. WAITING → next node |
| `skip()` | — | — | TYPING → reveals all chars → WAITING. Does NOT move to next node |
| `choose(index)` | `int` (1-based) | — | Select choice option. Splices branch nodes inline |
| `setSpeed(cps)` | `number` | — | Typewriter speed in chars/sec. 0 = instant |
| `getSpeed()` | — | `number` | |
| `getState()` | — | `string` | Current state string |
| `isActive()` | — | `boolean` | true if not IDLE and not DONE |
| `isWaitingForChoice()` | — | `boolean` | true only in CHOICE state |
| `currentSpeaker()` | — | `string` | Speaker name of current say node, or "" |
| `currentText()` | — | `string` | Full text of current say node, or "" |
| `revealedText()` | — | `string` | Typewriter-revealed substring |
| `getChoiceLabels()` | — | `{string}` | Choice option labels (1-indexed) |
| `getChoiceText()` | — | `string` | Prompt text for current choice node |
| `on(event, fn)` | `string, function` | — | Register callback (replaces previous) |
| `off(event)` | `string` | — | Clear callback for event |

### States

| State | Description |
|---|---|
| `"idle"` | Not started or reset |
| `"typing"` | Typewriter actively revealing text |
| `"waiting"` | Full text shown; awaiting advance() |
| `"choice"` | Presenting choices; awaiting choose() |
| `"paused"` | Executing a wait node; timer running |
| `"done"` | Script finished |

### Event Callbacks

| Event | When Fired | Callback Args |
|---|---|---|
| `"line"` | Entering every `say` node | `(speaker, text)` |
| `"choice"` | Entering a `choice` node | none |
| `"finished"` | Script completed | none |

### Script Format

Flat Lua array of node tables:

```lua
{ type = "say", speaker = "Alice", text = "Hello!" }
{ type = "choice", text = "Prompt?", options = {
    { label = "Yes", branch = { {type="say", speaker="Alice", text="Great!"} } },
    { label = "No",  branch = { {type="say", speaker="Alice", text="Oh..."} } },
}}
{ type = "call", fn = function() print("inline code") end }
{ type = "wait", time = 1.5 }
```

### API Contract Notes

- Branch parsing only handles `say`, `call`, `wait` — nested `choice` inside branches is silently skipped
- `off()` ignores the function argument; always clears the slot
- `speed = 0` reveals all text instantly in the same `update()` call
- `load()` resets all state; safe to call on a running sequencer

---

## Enums

None.

## Dependencies

- `common/Module.h`, `common/Object.h`, `common/runtime.h`
- **No external libraries**

## Registered Types

| Type | Inherits |
|---|---|
| `Sequencer` | `Object` |

---

## Extension Integration

The **Dialog Editor** panel (`luna2d.editor.dialogEditor`) provides a visual authoring tool for dialog scripts with real-time preview.

### Editor Features

- **5 node types**: 💬 Speech, 🔀 Choice, 📜 Narration, ⚡ Action, ❓ Condition
- Character management with emoji avatars and color indicators
- Live theatrical preview with clickable choices
- Tab navigation: Editor | Preview
- Export to **Lua** and **TOML** formats

### Extended Node Types

The Dialog Editor supports two additional node types beyond the core engine:

| Node Type | Badge Color | Fields | Description |
|---|---|---|---|
| `narration` | Purple | `text` | Narrator text with no speaker — used for scene descriptions and inner monologue |
| `condition` | Pink | `condition`, `trueBranch`, `falseBranch` | Conditional branching — evaluates a Lua expression to select which branch to follow |

> **Note**: The engine `Sequencer` currently supports `say`, `choice`, `call`, and `wait` node types. The `narration` and `condition` types are editor-level constructs that compile down to engine-supported types during export.

### Export Format (Lua)

```lua
-- Generated by Luna2D Extension Dialog Editor
return {
    characters = {
        alice = { name = "Alice", color = { 0.4, 0.7, 1.0 } },
        bob   = { name = "Bob",   color = { 1.0, 0.6, 0.3 } },
    },
    dialogs = {
        intro = {
            { type = "speech", character = "alice", text = "Hello!" },
            { type = "narration", text = "A moment of silence." },
            { type = "choice", text = "How do you respond?", options = {
                { label = "Greet back", goto = "greet" },
                { label = "Ignore",     goto = "ignore" },
            }},
            { type = "action", code = "player.mood = 'happy'" },
            { type = "condition", condition = "player.level > 5",
              truePath = "advanced", falsePath = "beginner" },
        },
    },
}
```

### Export Format (TOML)

```toml
[character.alice]
name = "Alice"
color = [0.4, 0.7, 1.0]

[character.bob]
name = "Bob"
color = [1.0, 0.6, 0.3]

[[dialog.intro.nodes]]
type = "speech"
character = "alice"
text = "Hello!"

[[dialog.intro.nodes]]
type = "narration"
text = "A moment of silence."

[[dialog.intro.nodes]]
type = "condition"
condition = "player.level > 5"
truePath = "advanced"
falsePath = "beginner"
```

---

## Game Design Role

- **Story delivery**: Author linear or branching conversations without Lua spaghetti.
- **Typewriter effect**: Advance text character-by-character at a configurable speed.
- **Player choices**: Present option menus; resume the chosen branch automatically.
- **Event hooks**: Trigger cutscene actions mid-dialogue (`on("line", fn)`, `on("finished", fn)`).
- **Variable binding**: Insert runtime values (`{player_name}`) and test conditions for branching.

---

## Module Boundaries

**vs luna.localization** — `t(key)` resolves a translation key into a string. Dialog passes that string to its typewriter. Localization resolves text; dialog sequences it.

**vs luna.quest** — Quest tracks global flags and variable state. Dialog reads those flags for conditional branches and writes them via `call` nodes. Quest is the DB; dialog is the narrator.

**vs luna.ai (behavior trees)** — BT is for NPC combat/movement decision making. Dialog sequences linear narrative.

**vs luna.gui** — GUI renders widgets. Dialog supplies the text content and state; a Lua dialog box draws it.

**vs luna.scene** — Scene manages screen transitions. Push a "dialogue" scene that owns a Sequencer in its update/draw.

---

## Recipes & Workflows

- **RPG conversations**: Branching NPC dialogue that writes quest flags on choices
- **Visual novels**: Linear script with portraits, typewriter, and auto-advance timer
- **Tutorial sequences**: Scripted hint delivery with `wait` nodes for timed pacing
- **Cutscenes**: Sequence dialogue + `call` nodes to move characters, trigger effects
- **Item inspection**: Short two-line say sequence when examining an object

---

## Planned / To Implement

- **W1 (MVP)**: DialogTree loader from JSON/Lua table; linear progression with `advance()`
- **W1**: Character name + portrait binding per line node
- **W2**: Condition-gated branches — evaluate game state expressions in branch conditions
- **W2**: Typewriter animation — reveal text character-by-character with configurable speed and punctuation pauses
- **W3**: Voice-line sync — play audio cue aligned to dialogue line with optional subtitle fallback
- **W3**: `luna.localization` integration — feed `t(key)` translated strings into the dialogue tree automatically
