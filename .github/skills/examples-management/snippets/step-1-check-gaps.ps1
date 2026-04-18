# Full summary of all modules
python tools/audit/example_coverage.py

# Missing items only
python tools/audit/example_coverage.py --missing

# Single module
python tools/audit/example_coverage.py --module timer

# CI gate: exit 1 if any gaps
python tools/audit/example_coverage.py --report
