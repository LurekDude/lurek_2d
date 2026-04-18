# Run batch, write reports
python tools/audit/audit_module.py --all

# Read reports to find patterns
Get-Content docs/quality/timer.md, docs/quality/physics.md, docs/quality/audio.md

# After fixing, re-run batch to verify all
python tools/audit/audit_module.py --all --docs-quality
