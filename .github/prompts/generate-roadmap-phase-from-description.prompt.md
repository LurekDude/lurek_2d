---
description: "Generate a roadmap phase file from a natural-language description."
---

# Generate Roadmap Phase From Description

## Goal
- Generate a complete Lurek2D roadmap phase file from a natural language description of scope and goals.

## Inputs
- Noun
- StructName
- domain
- module
- name
- slug
- verb

## Steps
- Load documentation, roadmap-planning before changing any files.
- **Feature domain** which Lurek2D module(s) does this touch? (graphics, physics, audio, input, filesystem, math, timer, window, data, image, sound, event, thread, system, or a new module)
- **Core capability** one sentence: what can the game developer do after this phase that they cannot do today?
- **Scope signal** is this a small addition (1 3 new functions), a medium module extension (new sub-system), or a large new module (brand-new src/<name>/ + lua_api/<name>_api.rs)?
- **Lua API surface sketch** list the lurek.* function names implied by the description. If none are named, invent canonical names following the lurek.<module>.<verb><Noun> pattern.
- **Rust implementation surface sketch** list the struct/trait/module names the implementation will likely need.
- docs/api/lurek.md what the current generated reference says
- Assign the next number (zero-padded, e.g. 19, 20).
- Choose a slug: lowercase-hyphenated, max 4 words, describes the feature not the status.
- Determine dependencies:
- Does this phase need SlotMap keys? Depends On Phase 1
- Does it need OO Lua objects (UserData)? Depends On Phase 13

## Success Criteria
- [ ] The Architect agent has produced the artifacts named in Goal.
- [ ] python tools/validate/cag_validate.py returns no new errors.

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /generate-roadmap-phase-from-description <Noun> <StructName> <domain> <module> <name> <slug> <verb>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation, roadmap-planning
- **Inputs required**: Noun, StructName, domain, module, name, slug, verb
