with open("src/lua_api/binary_api.rs", "r", encoding="utf-8") as f:
    c = f.read()

# Fix doubled Rust lifetime annotation quotes from PowerShell heredoc
c = c.replace("<''lua>", "<'lua>")
c = c.replace("''lua,", "'lua,")
c = c.replace("''lua Lua,", "'lua Lua,")
c = c.replace("''lua Lua>", "'lua Lua>")
# Fix remaining lifetime patterns
import re
c = re.sub(r"<''lua,", "<'lua,", c)
c = re.sub(r"<''lua>", "<'lua>", c)
c = re.sub(r"''lua\b", "'lua", c)

with open("src/lua_api/binary_api.rs", "w", encoding="utf-8") as f:
    f.write(c)
print("Done - fixed lifetimes")
