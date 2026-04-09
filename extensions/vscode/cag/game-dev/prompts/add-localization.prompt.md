---
name: Add Localization
description: Add multi-language support to the game.
mode: ask
---

# Add Localization

## Questions
1. Which languages?
2. Which locale is the source/default?

## Steps
1. Extract all string literals from Lua files
2. Route to **lua-scripter** to implement i18n/locale.lua
3. Generate i18n/en.toml with all extracted strings
4. Open Localization Editor for remaining translations
