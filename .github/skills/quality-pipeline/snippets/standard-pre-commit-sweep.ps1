python tools/gen_all_docs.py
python tools/audit/quality_report.py
python tools/validate/cag_validate.py
cargo test ; cargo clippy -- -D warnings
