# P0 Baseline and Gates

Owner: build-engineer

Done When:
- Fresh baseline report exists in work/<session>/reports.
- All baseline commands executed and results captured (pass or fail).
- Any tooling ambiguity has an explicit decision note.

Inputs:
- tools/gen_all_docs.py
- tools/audit/doc_coverage.py
- tools/audit/test_coverage.py
- tools/validate/cag_validate.py

Produces:
- work/<session>/reports/p0_baseline_status.md
- work/<session>/reports/p0_gate_results.md

Execution Steps:
1. Run baseline gates in this order:
	- cargo test
	- cargo clippy -- -D warnings
	- python tools/audit/doc_coverage.py
	- python tools/audit/test_coverage.py
	- python tools/gen_all_docs.py
	- python tools/validate/cag_validate.py --baseline
2. Record exact command status and key numbers in p0_gate_results.md.
3. Decide generator policy for tools/gen_all_docs.py:
	- whether coverage failure should fail generation command
	- how to report generator success vs audit failure
4. Decide and document missing_docs policy:
	- keep current policy, or
	- enforce missing_docs with migration plan
5. Add short follow-up TODO list for any failed gate.

Out of Scope:
- No feature implementation.
- No refactor outside tooling clarity and baseline reporting.
