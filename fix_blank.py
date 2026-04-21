"""Remove empty lines between /// doc and lua registration."""
import os
import re
import glob

for path in glob.glob("src/lua_api/*_api.rs"):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    
    # regex to eliminate blank lines between `/// Namespace ...` or `/// API ...` and `lurek.set(`
    text = re.sub(r'(///.*?\n)\s*\n(\s*tbl\.set|\s*lurek\.set|\s*graphic|\s*methods)', r'\1\2', text)
    # Another pattern for previous patches
    text = re.sub(r'(/// This is a detailed description.*?)\n\s*\n', r'\1\n', text)

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
