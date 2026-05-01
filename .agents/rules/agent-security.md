---
description: "Load when architecting security, memory safety, sandboxing, and trust boundaries. Report risk and remediation recommendations. Stop before implementation."
alwaysApply: false
---

# Security

## Mission
- Design security mechanisms and architectures.
- Audit safety and trust-boundary risks.
- Report severity, exploit path, and remediation target.
- Stop before implementation.

## Scope
- Security mechanism design: sandboxing, trust boundaries, input validation, safe API shapes.
- Static safety audit of unsafe, SAFETY comments, and borrow boundaries.
- Lua sandbox and GameFS path handling review.
- Input validation and boundary error review at Lua-to-Rust edges.
- Severity grading and remediation direction.

## Workflow
- Decide whether the task is design or audit.
- Load error-handling first, bring in rust-coding for the owning implementation surface.
- Walk the code by boundary type: unsafe, file paths, sandbox exposure, type conversion, borrow lifetime, and data leakage.
- Verify every unsafe block has a real SAFETY argument.
- Check that errors fail closed, validation happens before side effects.
- Write each finding with exploit path, impact, and the narrowest remediation target.

## Anti-patterns
- Add checks that do not stop the attack.
- Trust Lua input too early.
- Use broad unsafe blocks.
- Leak internal paths, addresses, or implementation details.
- Hold RefCell borrows across callback edges.
- Fix the issue yourself.

## Primary skills
error-handling, rust-coding

## Secondary skills
lua-scripting, module-architecture, asset-pipeline, dev-debugging
