# `dialog` - Agent Reference (Lunasome)

| Property              | Value                                                                                                                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**              | Tier 3 - Lunasome (pure Lua, no Rust dependencies)                                                                                                                                       |
| **Source**            | `library/dialog/init.lua`                                                                                                                                                                |
| **Lua Tests**         | `tests/lua/library/test_library_dialog.lua`                                                                                                                                              |
| **Depends on**        | `lurek.*` public API only                                                                                                                                                                |
| **Test count**        | 40 tests, 40 passing                                                                                                                                                                     |
| **Status**            | full                                                                                                                                                                                     |
| **Optional bindings** | `lurek.patterns.newEventBus` (mirrors events to a bus when present), `lurek.i18n.t` (recommended for translatable line text), `lurek.serial.toJson/fromJson` (script persistence) |

## Summary

Typewriter-style dialogue sequencer with branching choices and event hooks.
`Sequencer` drives a linear or branching conversation through a list of nodes
each frame. It exposes `:on(event, fn)` for five lifecycle hooks: `line`
(say node started), `typewrite` (character-by-character reveal), `choice`
(choice node started), `event` (named script signal), `finished`/`done`
(sequence exhausted).

Nodes are plain Lua tables created by helper functions: `M.say(actor, text,
opts)` creates a spoken line, `M.choice(prompt, options)` presents a branch
point, `M.wait(seconds)` inserts a timed delay, `M.event(name, data)` fires a
named hook, `M.call(fn)` runs an arbitrary callback inline, and `M.jump(label)`
transfers control to a named node. Any node may carry a `cond` function predicate
and a `label` string field.

`Sequencer:update(dt)` advances the typewriter timer and fires `typewrite`
per newly revealed character. `Sequencer:choose(index)` resolves a pending
choice node by splicing its branch inline.

The module carries no engine state or GPU dependencies.

## Architecture

```
Sequencer
  |
  |-- _nodes: { Node, ... }     flat array, branches spliced inline on choose()
  |-- _pc: number               program counter
  |-- _revealed: float          typewriter progress (fractional chars)
  |
  |-- Lifecycle hooks (via :on(event, fn))
  |     |-- line(speaker, text)         say node started
  |     |-- typewrite(char, full_text)  per newly revealed character
  |     |-- choice()                    choice node started
  |     |-- event(name, data)           event node processed
  |     |-- finished()                  sequence ended
  |     +-- done()                      alias for finished
  |
  +-- Node types (all may carry .cond and .label fields)
        |-- say    { type, speaker, text }
        |-- choice { type, text, options: [{ label, branch[] }] }
        |-- wait   { type, time }
        |-- event  { type, name, data }
        |-- call   { type, fn }
        +-- jump   { type, target }

M.NodeType       --  SAY | CHOICE | WAIT | EVENT | CALL | JUMP
M.SequencerState --  IDLE | TYPING | WAITING | CHOICE | PAUSED | DONE
                     (legacy aliases: RUNNING=TYPING, WAITING_CHOICE=CHOICE)
```

## Source Files

| File                      | Purpose                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `library/dialog/init.lua` | Full implementation: Sequencer, node constructors, NodeType + SequencerState enums |

## Key Types

| Type               | Constructor                       | Purpose                                               |
| ------------------ | --------------------------------- | ----------------------------------------------------- |
| `Sequencer`        | `M.newSequencer()`                | Frame-ticked dialogue runner                          |
| say node           | `M.say(actor, text, opts)`        | Spoken line with typewrite reveal                     |
| choice node        | `M.choice(prompt, options, opts)` | Branching prompt                                      |
| wait node          | `M.wait(seconds, opts)`           | Timed delay node                                      |
| event node         | `M.event(name, data, opts)`       | Named hook signal                                     |
| call node          | `M.call(fn, opts)`                | Inline callback                                       |
| jump node          | `M.jump(target, opts)`            | Label-based control transfer                          |
| `M.NodeType`       | enum table                        | Type constants (SAY, CHOICE, WAIT, EVENT, CALL, JUMP) |
| `M.SequencerState` | enum table                        | State constants matching `seq:getState()`             |

## Sequencer API

### Core flow

| Method          | Description                                                   |
| --------------- | ------------------------------------------------------------- |
| `load(nodes)`   | Load script. Resets all state.                                |
| `start()`       | Begin playback. Empty script fires done/finished immediately. |
| `update(dt)`    | Advance timer and typewrite. Call every frame.                |
| `advance()`     | TYPING completes reveal; WAITING moves to next node.          |
| `skip()`        | TYPING instantly shows full text, enters WAITING.             |
| `choose(index)` | Select choice option (1-based); splices branch inline.        |

### State queries

| Method                 | Returns | Description                                         |
| ---------------------- | ------- | --------------------------------------------------- |
| `getState()`           | string  | One of: idle, typing, waiting, choice, paused, done |
| `isActive()`           | boolean | true if not idle and not done                       |
| `isWaitingForChoice()` | boolean | true in choice state only                           |
| `currentSpeaker()`     | string  | Speaker of current say node, or empty string        |
| `currentText()`        | string  | Full text of current say node, or empty string      |
| `revealedText()`       | string  | Typewriter-revealed substring                       |
| `getChoiceText()`      | string  | Prompt of current choice node, or empty string      |
| `getChoiceLabels()`    | table   | Array of option labels for current choice           |
| `getSpeed()`           | number  | Typewriter speed in chars/sec                       |

### Configuration

| Method          | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| `setSpeed(cps)` | Typewriter speed (default 20). 0 means text never advances.                |
| `on(event, fn)` | Register callback. Events: line, typewrite, choice, event, finished, done. |
| `off(event)`    | Remove all callbacks for event.                                            |

## Node cond and label

- `cond = function() return bool end` -- when false, node is skipped silently.
- `label = "name"` -- makes the node a jump target.

```lua
dialog.say("NPC", "Hi!", { cond = function() return flags.met_npc end, label = "greeting" })
```
