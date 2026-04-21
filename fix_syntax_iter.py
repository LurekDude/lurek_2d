import os
import subprocess
import glob
import re

def fix_file(path):
    print(f"Fixing {path}...")
    while True:
        res = subprocess.run(['luac', '-p', path], capture_output=True)
        if res.returncode == 0:
            print("  Fixed!")
            break
            
        out = res.stderr.decode().strip()
        match = re.search(r':(\d+): (.+expected.*near.+)$', out)
        if not match:
            print(f"  Cannot parse error: {out}")
            break
            
        line_num = int(match.group(1))
        error_msg = match.group(2)
        
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        if line_num <= len(lines):
            print(f"  Deleting line {line_num}: {lines[line_num-1].strip()} ({error_msg})")
            del lines[line_num - 1] # Delete the offending line
            with open(path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
        else:
            # if line_num is past EOF, it means missing end.
            if error_msg.startswith('<eof> expected') or error_msg.startswith("'<eof>' expected"):
                # this means there is an extra end somewhere, maybe at eof, but luac points past eof
                found = False
                for i in range(len(lines) - 1, -1, -1):
                    if lines[i].strip() in ('end)', 'end'):
                        print(f"  Deleting trailing end at {i+1}")
                        del lines[i]
                        found = True
                        break
                if not found:
                    print("  Cannot fix missing/extra end.")
                    break
                with open(path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
            else:
                # literally missing an end
                print("  Appending 'end)'")
                lines.append('end)\n')
                with open(path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)

for p in glob.glob('tests/lua/evidence/*.lua'):
    fix_file(p)

print("Done")