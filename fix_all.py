import glob, subprocess, re

for path in glob.glob('tests/lua/**/*.lua', recursive=True):
    res = subprocess.run(['luac', '-p', path], capture_output=True)
    if res.returncode == 0: continue

    print(f"Fixing {path}")
    with open(path, 'rb') as f: raw = f.read()
    try:
        content = raw.decode('utf-8', errors='ignore')
    except:
        content = raw.decode('latin-1', errors='ignore')

    def check(c):
        with open('temp.lua', 'w', encoding='utf-8') as f: f.write(c)
        r = subprocess.run(['luac', '-p', 'temp.lua'], capture_output=True)
        return r.returncode == 0

    orig = content.split('\n')
    for i in range(20):
        found = False
        for j in range(len(orig)-1, -1, -1):
            if orig[j].strip() in ('end', 'end)', 'end,', 'end})', '});'):
                del orig[j]
                found = True
                break
        if not found: break
        
        c2 = '\n'.join(orig)
        if check(c2):
            with open(path, 'w', encoding='utf-8') as f: f.write(c2)
            print("  Fixed by removing trailing end")
            break

print("Done")
