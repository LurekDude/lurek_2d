#!/usr/bin/env python3
"""
Remove all //, ///, //! comments from Rust files in src/
Keep code intact, remove comment-only lines.
"""
import os
import re

def strip_rust_comments(filepath):
    """Strip all // comments from a Rust file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    for line in lines:
        # Check if line is a comment-only line (whitespace + comment)
        stripped = line.lstrip()
        if stripped.startswith('//'):
            # Skip comment-only lines entirely
            continue
        
        # Remove inline comments from code lines
        # Match // /// //! but preserve string contents
        # Simple approach: find // and remove everything after unless in string
        code_part = line
        
        # Remove // comments (but be careful with strings)
        # This is a simple regex that handles most cases
        in_string = False
        result = []
        i = 0
        while i < len(code_part):
            # Check for string start/end
            if code_part[i] == '"' and (i == 0 or code_part[i-1] != '\\'):
                in_string = not in_string
                result.append(code_part[i])
                i += 1
            # Check for comment start
            elif not in_string and i + 1 < len(code_part) and code_part[i:i+2] == '//':
                # Found comment, stop here
                break
            else:
                result.append(code_part[i])
                i += 1
        
        stripped_line = ''.join(result).rstrip()
        if stripped_line:  # Only add non-empty lines
            new_lines.append(stripped_line + '\n')
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print(f"Processed: {filepath}")

# Walk through src/
src_dir = r'c:\Users\tombl\Documents\lurek2D\src'
for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith('.rs'):
            filepath = os.path.join(root, file)
            strip_rust_comments(filepath)

print("Done! All comments removed from Rust files in src/")
