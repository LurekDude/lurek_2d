# Localization Demo

Demonstrates `luna.localization`: multi-language strings, interpolation, pluralization, and on-the-fly language switching.

## What It Demonstrates

- `luna.localization.load()` — register translation tables
- `luna.localization.t()` — translate a key to the current language
- Interpolation: `t("greeting", {name = "Alice"})` → `"Hello, Alice!"`
- Pluralization: select form based on count
- `luna.localization.setLanguage()` — switch language at runtime
- Fallback: default to a base language when a key is missing

## How to Run

```powershell
cargo run -- demos/localization_demo
```

## Controls

| Key | Action |
|-----|--------|
| L | Cycle through available languages |
| + / - | Change item count (demos pluralization) |

## Notes

- Built-in languages: English, French, German, Spanish, Japanese
- Add new languages by registering additional translation tables
