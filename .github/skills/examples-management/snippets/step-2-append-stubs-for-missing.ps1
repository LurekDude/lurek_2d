# Dry-run first to preview what will be appended
python tools/audit/example_add_missing.py --module timer --dry-run

# Write stubs for one module
python tools/audit/example_add_missing.py --module timer

# Write stubs for all modules with gaps
python tools/audit/example_add_missing.py
