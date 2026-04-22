# tools/demos/

Demo-folder maintenance for `content/demos/`: structural fixes, screenshot regeneration, and smoke testing.

## Scripts

| Script | Purpose | Key args |
|---|---|---|
| `organize_demos.py` | Three-in-one demos maintenance tool (rename/sort/normalise structure) | `--dry-run` |
| `gen_demo_screenshots.py` | Capture a `screen.png` for every demo by launching the release binary headlessly | `--demo NAME`, `--overwrite`, `--rebuild` |
| `smoke_sweep.py` | Smoke-test all playable demos/examples by launching each and checking for crashes | `--timeout SECS`, `--demo NAME` |

## Common usage

```powershell
python tools/demos/organize_demos.py --dry-run     # preview structural fixes
python tools/demos/gen_demo_screenshots.py          # regenerate all screenshots
python tools/demos/gen_demo_screenshots.py --demo hello_world  # one demo
python tools/demos/smoke_sweep.py                   # smoke-test all projects
```
