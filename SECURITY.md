# Security Policy

## Reporting a Vulnerability

Please do not report suspected vulnerabilities through public GitHub issues, pull requests, discussions, or social media.

Preferred reporting workflow:

1. Use GitHub private vulnerability reporting for this repository, if it is enabled.
2. If private reporting is not enabled, contact the maintainer through a private channel published by the repository owner.
3. If no private channel is available, open a public issue only to request a private contact path. Do not include exploit details, proof of concept code, or sensitive logs in that issue.

## What To Include

Please include as much of the following as practical:

- A short description of the issue and expected impact
- Affected version, tag, or commit
- Host platform and environment details
- Clear reproduction steps or a minimal proof of concept
- Whether the issue allows sandbox escape, path traversal, arbitrary file access, code execution, or denial of service
- Any relevant logs, screenshots, or crash output with secrets removed

## Supported Scope

This policy applies to the Lurek2D source repository and release artifacts produced from it.

Lurek2D is a desktop-only 2D engine. Security support is handled on a best-effort basis for:

- The current `main` branch
- The latest published release

Older releases may not receive backports.

In-scope areas include:

- The Rust engine runtime and bundled tools in this repository
- Lua sandbox escapes
- Filesystem sandbox and path traversal issues
- Memory safety issues and unintended arbitrary code execution
- Dependency vulnerabilities that materially affect shipped artifacts

## Out of Scope

The following are generally out of scope for this repository's security process:

- iOS, Android, WASM, browser, or other unsupported targets
- Hosted service, cloud backend, telemetry, or server-side issues because Lurek2D does not provide those services
- Vulnerabilities in third-party games, scripts, assets, or mods that are not reproducible in Lurek2D itself
- Bugs that only let a local script hang or crash its own process without escaping the Lua sandbox or accessing data outside allowed boundaries
- Feature requests, hardening ideas without a concrete vulnerability, or purely theoretical reports without a plausible attack path

## Disclosure Expectations

Please keep vulnerability details private until the maintainers have had a reasonable opportunity to investigate and prepare a fix or mitigation.

This is a small open source project, so response times are best effort and no formal SLA is promised. Coordinated disclosure is preferred. Public writeups and proof of concept material should wait until:

- A fix is available, or
- The maintainers confirm that disclosure can proceed without increasing risk

If you do not receive a response, send a follow-up through the same private channel rather than posting full details publicly.
