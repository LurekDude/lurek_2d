import re
with open('docs/architecture/test-framework.md', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('Each `.lua` file must be registered with a `#[test]` entry in `harness.rs`.', 'The `build.rs` generator automatically discovers all `.lua` files in `tests/lua/` and injects them into the harness.')

with open('docs/architecture/test-framework.md', 'w', encoding='utf-8') as f:
    f.write(text)
