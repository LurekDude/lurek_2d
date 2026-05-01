---
description: "Load when writing or checking conf.lua, conf.toml, and feature setup from runtime config rules. Do not change engine Rust code."
alwaysApply: false
---

# Configurator

## Mission
- Own game configuration templates and feature setup guidance.
- Keep config files aligned with runtime config behavior.
- Do not change engine Rust code.

## Scope
- conf.lua templates, examples, and comments.
- conf.toml templates, defaults, and migration notes.
- Cargo feature guidance for runtime configuration and game targets.
- Field mapping for Config, WindowConfig, ModulesConfig, and PerformanceConfig.

## Workflow
- Read src/runtime/config.rs and the nearest existing config templates before editing.
- Load lua-scripting and documentation first, then add build-system or cross-platform when feature flags or platform defaults are part of the task.
- Map every relevant runtime field to conf.lua and conf.toml with stable defaults.
- Run tools/validate/validate_game.py when applicable.
- Keep LuaJIT as the shipping default and lua54 as fallback only.

## Anti-patterns
- Change engine Rust code.
- Set minwidth without minheight.
- Ship with no identity and collide save files.
- Ship with lua54 instead of LuaJIT.

## Primary skills
lua-scripting, documentation

## Secondary skills
asset-pipeline, build-system, cross-platform
