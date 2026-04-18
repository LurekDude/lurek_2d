| Complexity | Lines | Examples |
|------------|-------|---------|
| Minimal | 50–100 | `hello_world` |
| Simple | 100–160 | `sprites`, `physics_demo` |
| Standard | 160–300 | `platformer`, `card_game` |
| Complex | 300–400 | `roguelike`, `deckbuilder` |

Never exceed 400 lines — if logic grows larger, extract helpers or split into multiple demos.

### Step 4 — Library Modules

When the prompt requests `content/library/` modules, see [library-integration](./references/library-integration.md) for full patterns. Quick reference:

**Import pattern** (always at top of file, after header comment):
> See [examples/step-4-library-modules.lua](examples/step-4-library-modules.lua) for the example.

**Only use modules with ✅ Full status** (stub modules are unusable):

| Module | Status | What It Provides |
|--------|--------|-----------------|
| `library.dialog` | ✅ Full | Typewriter sequencer, branching choices, event callbacks |
| `library.item` | ✅ Full | Item type definitions, instance creation, stat lookup |
| `library.inventory` | ✅ Full | Slot-based inventory management |
| `library.province_map` | ✅ Proxy | Province/region map (wraps `lurek.province`) |
| `library.battle`, `.stats`, `.economy`, `.crafting`, `.cardgame`, `.combat`, `.quest` | 🔧 Stub | Do NOT use — causes runtime errors |

Call library functions at the top of `lurek.load()` before any `lurek.*` drawing setup:
> See [examples/step-4-library-modules-2.lua](examples/step-4-library-modules-2.lua) for the example.

### Step 5 — Write `README.md`

> See [snippets/step-5-write-readme-md.md](snippets/step-5-write-readme-md.md) for the example.

### Controls
| Key | Action |
|-----|--------|
| Escape | Quit |
| <Key> | <Action> |

### Notes
- <Optional: 2–4 bullets on non-obvious design choices or limitations>
> See [snippets/notes.txt](snippets/notes.txt) for the example.

Requirements: the release binary must exist (`cargo build --release` or use `--rebuild` flag).

If the binary is fresh:
> See [snippets/notes-2.ps1](snippets/notes-2.ps1) for the example.

### Step 7 — Register in `content/demos/README.md`

Append to the `## Demo Index` table:
> See [snippets/step-7-register-in-content-demos.md](snippets/step-7-register-in-content-demos.md) for the example.

Then append a detail block at the end of the per-demo sections:
> See [snippets/step-7-register-in-content-demos-2.md](snippets/step-7-register-in-content-demos-2.md) for the example.

---
```

---

### Batch Creation Workflow
When generating N > 1 demos from a list of genres:

1. Derive names for all demos first — confirm no name collisions
2. Generate `conf.toml` + `main.lua` for each in order
3. Generate all `README.md` files
4. Run screenshot tool for all at once:
   ```powershell
   python tools/demos/gen_demo_screenshots.py --demo <n1> --demo <n2> ... --overwrite --frames 3
   ```
5. Register all demos in `content/demos/README.md` in one edit (alphabetical order)

---

### Genre → API Mapping Reference
See [genre-patterns](./references/genre-patterns.md) for a pre-mapped table of common genres and their recommended `lurek.*` API namespaces, library modules, and structural patterns.

---

### Quality Checklist
Before marking a demo complete:

- [ ] `conf.toml` — title matches demo name, valid resolution, target_fps = 60
- [ ] `main.lua` — all 4 callbacks present; `escape` quits; no globals; dt used for movement
- [ ] `main.lua` — only `lurek.*` API calls and optionally approved `library.*` requires
- [ ] `main.lua` — no `print()` statements; debug output via `lurek.log.debug()`
- [ ] `README.md` — 4 required sections present; `What It Demonstrates` matches actual code
- [ ] `screen.png` — generated and present (non-zero file size)
- [ ] `content/demos/README.md` — table entry added; detail block added
- [ ] `cargo run -- content/demos/<name>` — runs without errors or unhandled exceptions
- [ ] `cargo check` — no type errors introduced
