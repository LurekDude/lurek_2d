# Single module — writes docs/quality/<module>.md, prints one line
python tools/audit/audit_module.py <module>

# All modules — writes 46 reports, prints one line per module + summary
python tools/audit/audit_module.py --all

# Tier subset
python tools/audit/audit_module.py --group platform-services

# JSON output (structured, for programmatic use)
python tools/audit/audit_module.py <module> --json
