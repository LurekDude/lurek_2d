---
description: "Run the .agents/ rule and workflow validation pass."
---

# Run CAG Validation

## Goal
- Verify the .agents/ layer passes all validation rules.

## Inputs
- Scope (all or specific file/type).

## Steps
1. Load tools-cag-validation and cag-workflow before acting.
2. Run python tools/validate/cag_validate.py for the target scope.
3. If the scope includes file relationships, run tools/audit/cag_link_check.py.
4. For roster or coverage checks, run tools/audit/cag_coverage.py.
5. Fix any validation errors in the correct source file, not by changing the validator rule.
6. Re-run the full pass after all fixes.

## Success Criteria
- [ ] cag_validate.py passes clean.
- [ ] cag_link_check.py passes if file relationships were touched.
- [ ] No content defects remain.

## Anti-patterns
- Silence errors by changing the validator instead of the source file.
- Skip the full pass after fixing individual files.

## Example Invocation
- /run-cag-validation scope=all
