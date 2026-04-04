with open("src/binary/pack.rs", "r", encoding="utf-8") as f:
    c = f.read()

# In pack.rs, the ''word'' patterns appear in error message format strings
# and in doc comments. Fix them:
# In error strings (format!(...)) replace ''token'' with '{token}'
# The issue: PowerShell wrote ''other'' as ''other'' when we meant to write
# the format string: format!("luna.binary: unknown format token '{other}'")
# PowerShell heredoc doubled ''other'' to ''other'' which is wrong.

# Fix format strings: ''X'' -> 'X'  (in string literals)
import re

# Replace ''word'' with 'word' everywhere (error msg strings + doc comments)
c = re.sub(r"''([^']+)''", r"'\1'", c)

with open("src/binary/pack.rs", "w", encoding="utf-8") as f:
    f.write(c)
print("Done - fixed pack.rs quotes")
