---
description: "Run a security audit on one module or trust boundary."
---

# Review Security Audit

## Goal
- Audit one module or boundary for security risks and remediation.

## Inputs
- Target module or attack surface.
- Threat model or severity threshold.
- Known unsafe blocks or boundary hotspots.

## Steps
1. Load error-handling and rust-coding before acting.
2. Identify trust boundaries, attack surfaces, and assets.
3. Walk the code by boundary type: unsafe, file paths, sandbox exposure, type conversion, borrow lifetime, and data leakage.
4. Verify every unsafe block has a real SAFETY argument.
5. Check that errors fail closed and logs do not leak sensitive paths.
6. Return findings with severity, file, line, attack scenario, and remediation target.

## Success Criteria
- [ ] Each blocker has a plausible attack path and impact.
- [ ] Severity matches reachable behavior.
- [ ] Hardening advice is separate from exploitable findings.
- [ ] Unsafe, paths, conversions, and logs were checked.

## Anti-patterns
- Trust Lua input too early.
- Treat theoretical risk with no reachable path as a proven exploit.
- Fix the issue yourself.

## Example Invocation
- /review-security-audit module=filesystem
