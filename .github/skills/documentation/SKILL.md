---
name: documentation
description: "Load this skill when writing or updating Luna2D documentation: API reference, architecture docs, tutorials, README, or code comments. It owns doc style, structure, and accuracy verification. Skip it for code implementation."
---

# Documentation — Luna2D Engine

## Load When

- Writing or updating `docs/` files
- Updating `README.md`
- Writing code comments for complex algorithms
- Creating tutorials or getting-started guides
- Documenting new API functions

## Owns

- Documentation structure and style
- API reference format and accuracy
- Architecture documentation
- Tutorial and getting-started content
- Code comment conventions

## Does Not Cover

- CAG file documentation → use `tools-cag-validation` skill
- Code implementation → use `rust-coding` skill
- API design decisions → use `lua-api-design` skill

## Live Repository Contracts

- `docs/lua_api_reference.md` — complete Lua API documentation
- `docs/architecture.md` — engine architecture overview
- `docs/getting_started.md` — setup and first-game guide
- `README.md` — project overview and quick start

## Decision Rules

- **Accuracy first**: Every documented API must match the actual code signature
- **Working examples**: Code snippets in docs must be runnable
- **One source of truth**: Don't duplicate information across doc files — cross-reference
- **Lua perspective**: API reference written for Lua script authors, not Rust developers
- **Function format**: `luna.module.function(param1, param2)` — Returns: description
- **Getting started**: Must produce a working game from zero knowledge
- **Architecture**: Must reflect current module structure — update when modules change
- **Markdown style**: Headers with `##`, code blocks with language tags, tables for reference data
