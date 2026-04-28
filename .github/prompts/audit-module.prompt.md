---
description: "Run an end-to-end audit for one or more src/ modules."
---
# Audit Module

## Goal
- Run a full audit for one or more src/ modules.

## Inputs
- module_names: target module list.

## Steps
- Load module-audit, documentation, testing-rust, and module-architecture.
- Read the target module specs first.
- Run the audit tools that match module docs, tests, and structure.
- Group findings by module and issue type.
- Add remediation guidance.
- Keep the audit read-only.

## Success Criteria
- [ ] Each target module was audited.
- [ ] Findings are grouped clearly.
- [ ] Remediation guidance is listed.

## Anti-patterns
- Fix code during the audit.
- Skip the module specs.
- Mix unrelated modules into one report.

## Example Invocation
- /audit-module module_names

## CAG Metadata
- **Mode**: agent
- **Loads skills**: module-audit, documentation, testing-rust, module-architecture
- **Inputs required**: module_names
