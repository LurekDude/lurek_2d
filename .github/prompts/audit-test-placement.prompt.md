---
description: "Audit test placement rules in src/, src/lua_api/, and mod.rs files."
agent: Tester
loads_tools:
 - tools/audit/inline_test_audit.py
 - tools/audit/thin_wrapper_audit.py
 - tools/audit/thin_modrs_audit.py
 - tools/audit/test_coverage.py
---
# Audit Test Placement

## Goal
- Audit TST-01 to TST-04 placement rules and produce a read-only report.

## Inputs
- target_scope: src/, src/<module>/, or one src/<module>/<file>.rs path. Default is src/.

## Steps
- Load testing-rust, lua-rust-bridge, and module-architecture.
- Resolve target_scope.
- Run inline_test_audit.py for TST-02.
- Run thin_wrapper_audit.py for TST-03.
- Run thin_modrs_audit.py for TST-04.
- Run test_coverage.py for the TST-01 cross-check.
- Group findings by TST rule and file.
- Add one remediation hint per finding.
- Write the report to work/<session>/reports/test-placement-audit.md.
- Append one JSONL log entry to work/<session>/logs/agent_log.jsonl.
- Do not modify src/, tests/, or Cargo.toml in this prompt.

## Success Criteria
- [ ] All needed audit scripts ran for target_scope, or the report states which script is missing.
- [ ] work/<session>/reports/test-placement-audit.md lists each violation with file, line, rule, and remediation hint.
- [ ] The report summary includes counts per TST rule.
- [ ] python tools/validate/cag_validate.py reports no new errors.

## Anti-patterns
- Auto-fix violations during the audit.
- Skip the tests/lua/ @covers cross-check.
- Ignore a narrower target_scope.
- Use git add .
- Declare done before checking Success Criteria.

## Example Invocation
- /audit-test-placement src/tween/

## CAG Metadata
- **Mode**: agent
- **Loads skills**: testing-rust, lua-rust-bridge, module-architecture
- **Inputs required**: target_scope
