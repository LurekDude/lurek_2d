# Localization Demo

Demonstrates `lurek.localization`: multi-language strings, interpolation, pluralization, and on-the-fly language switching.

## What It Demonstrates

- `lurek.localization.load()` — register translation tables
- `lurek.localization.t()` — translate a key to the current language
- Interpolation: `t("greeting", {name = "Alice"})` → `"Hello, Alice!"`
- Pluralization: select form based on count
- `lurek.localization.setLanguage()` — switch language at runtime
- Fallback: default to a base language when a key is missing

## How to Run

```powershell
cargo run -- content/demos/localization_demo
```

## Controls

| Key | Action |
|-----|--------|
| L | Cycle through available languages |
| + / - | Change item count (demos pluralization) |

## Notes

- Built-in languages: English, French, German, Spanish, Japanese
- Add new languages by registering additional translation tables
