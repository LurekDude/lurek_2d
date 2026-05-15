# Lurek2D - Linux Build and Distribution Guide

Date: 2026-05-15
Scope: research + execution plan, no source changes
Audience: engine contributor / release owner

## 1. Assumptions

This guide follows the user constraints from this session:

- Full feature set stays in core.
- Plugins, if introduced, are additive extensions, not a way to cut existing core functionality out of the main binary.
- Linux desktop is the target. Mint / Ubuntu-family and Fedora are the primary reference distros.
- The goal is a practical shipping path first, not a theoretical minimum-size experiment.

## 2. Executive Decision

Recommended primary shipping target:

- `x86_64-unknown-linux-gnu`

Recommended first Linux distribution format:

- portable folder + `tar.xz`
- optional second artifact: AppImage

Recommended raw binary compression policy:

- first choice: UPX on Linux ELF, if accepted operationally
- best mainstream alternative to UPX: AppImage compression or `tar.xz` packaging compression
- do not use `gzexe` as the default shipping method
- do not use `sstrip` as the default shipping method

Recommended cross-build path from Windows:

- first choice: WSL2 Ubuntu or Fedora container
- second choice: `cross` with a controlled glibc baseline image

Recommended secondary target status:

- `x86_64-unknown-linux-musl` stays experimental for this project, not the default shipping target

## 3. What The Repo Says Today

Observed repo facts:

- Linux is a declared desktop target in `docs/architecture/philosophy.md` and `docs/architecture/engine-architecture.md`.
- The Linux/macOS packager exists as `tools/dist/dist.sh`.
- The Linux installer exists as `tools/dist/install.sh`.
- The Cargo wrapper already supports `build dist` through `tools/dev/parallel_cargo.py`.
- The Windows packager uses `build dist` and UPX.
- The Linux packager currently builds `release`, not `dist`.
- `profile.dist` currently only inherits `release`; it is not yet more size-oriented than `release`.
- The `<= 10 MB` target is still marked as proposed architecture, not an active enforced contract.
- `.github/workflows/` is empty in this checkout, so Linux CI is not actually present right now.

Practical consequence:

- Linux support exists, but the Linux release path is not yet as mature or size-focused as the Windows one.
- With the current repo state, the main Linux deliverable should be treated as "works reliably" first, then "smaller" second.

## 4. Important Constraint Clash

There is a direct clash between the current proposed plugin architecture and the user constraint for this session.

Repo proposal:

- `docs/architecture/plugins.md` proposes shrinking the core binary by extracting optional-by-nature modules from the main binary.

Session constraint:

- core must keep the full feature set
- plugins may add functionality, but must not become a binary-size escape hatch for removing existing core systems

Decision for this guide:

- do not rely on plugin extraction to hit Linux size goals
- size work must focus on build profile tuning, symbol handling, section stripping, and packaging
- any plugin work discussed here is additive only

Result:

- a raw uncompressed Linux ELF around 10 MB is not a realistic short-term target under the full-core assumption
- a compressed release artifact around that range is more realistic than a raw ELF at that range

## 5. Recommended Linux Support Contract

Primary support contract:

- host target: `x86_64-unknown-linux-gnu`
- runtime target: modern desktop distros with Vulkan loader, audio stack, and XDG portal support
- validation distros: Linux Mint LTS and Fedora latest stable

Distribution contract:

- build on Linux or in a controlled Linux container
- package as portable folder
- compress folder as `tar.xz`
- optionally provide AppImage for easier end-user launch

Why this is the right baseline:

- `wgpu` on Linux uses Vulkan in this repo
- `rodio` / `cpal` on Linux require ALSA at build time
- `rfd` on Linux expects XDG Desktop Portal or GTK fallback behavior at runtime
- `native-tls` uses OpenSSL on Linux
- all of that matches `gnu` much more naturally than a strict `musl` workflow for a GUI engine

## 6. Build Host Requirements

### 6.1 Linux Mint / Ubuntu-family

Build host packages:

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  pkg-config \
  python3 \
  python3-venv \
  git \
  curl \
  libasound2-dev \
  libssl-dev \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  zenity \
  libvulkan1 \
  mesa-vulkan-drivers
```

Notes:

- `libasound2-dev` is required because Linux audio builds through ALSA.
- `libssl-dev` is needed because `native-tls` uses OpenSSL on Linux.
- `xdg-desktop-portal` plus a backend such as `xdg-desktop-portal-gtk` is needed for file dialogs from `rfd`.
- `zenity` is also required by `rfd` for message dialogs and as a fallback path.
- `libvulkan1` and a working Vulkan driver stack are needed for runtime.
- On NVIDIA, install the vendor Vulkan driver stack instead of relying only on Mesa packages.

### 6.2 Fedora

Build host packages:

```bash
sudo dnf install -y \
  gcc \
  gcc-c++ \
  pkgconf-pkg-config \
  python3 \
  git \
  curl \
  alsa-lib-devel \
  openssl-devel \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  zenity \
  vulkan-loader \
  mesa-vulkan-drivers
```

Notes:

- `openssl-devel` is the Fedora equivalent of `libssl-dev`.
- `alsa-lib-devel` is the Fedora equivalent of `libasound2-dev`.
- KDE users may prefer `xdg-desktop-portal-kde` instead of the GTK portal backend.

## 7. Runtime Requirements For End Users

The shipped Linux build is not a fully isolated runtime. End users need:

- Vulkan loader and a working GPU driver
- ALSA-compatible audio stack
- XDG portal backend for native dialogs
- `zenity` for dialog fallback paths
- OpenSSL runtime libraries when using the current `native-tls` setup on `gnu`

Minimum practical desktop expectation:

- Mint Cinnamon / Ubuntu GNOME / Fedora Workstation should be fine once the packages above exist
- very minimal window-manager-only installs will need manual runtime dependency setup

## 8. Native Build Playbook

### 8.1 First-time setup

```bash
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
rustup default stable
rustup component add rustfmt clippy
```

The repo already pins stable in `rust-toolchain.toml`, so do not override it with nightly.

### 8.2 Verify toolchain and workspace

```bash
rustc --version
cargo --version
python3 --version
```

### 8.3 Build and test

Preferred sequence:

```bash
python3 tools/dev/parallel_cargo.py build release
python3 tools/dev/parallel_cargo.py test rust
python3 tools/dev/parallel_cargo.py test lua
python3 tools/dev/parallel_cargo.py clippy --deny-warnings
```

### 8.4 Package current Linux artifact

Current repo path:

```bash
bash tools/dist/dist.sh
```

Important limitation today:

- this script currently builds `release`, not `dist`
- if no repo changes are made, this is still the correct documented path for current Linux packaging, but it is not the final size-optimized path

## 9. Cross-Build From Windows

### 9.1 Recommended route: WSL2

Recommended WSL distro:

- Ubuntu LTS

Inside WSL2, use the exact Linux Mint / Ubuntu-family package and build steps from sections 6 and 8.

Why WSL2 is the best Windows-side path:

- you are still using an actual Linux userspace
- package names and dependency resolution match desktop Linux better
- fewer surprises than raw Windows cross-linker setups

Caveat:

- WSL2 is good for build and some CLI validation
- GUI, Vulkan, dialogs, and audio still need validation on a real Linux desktop or VM before release

### 9.2 Secondary route: `cross`

Use `cross` only after the native Linux build works.

Recommended direction:

- keep `x86_64-unknown-linux-gnu` as the main target
- use a controlled old-glibc image for portability

Recommended image idea:

- `ghcr.io/cross-rs/x86_64-unknown-linux-gnu:main-centos`

Why:

- this gives a glibc 2.17 baseline instead of inheriting whatever newest distro your build host happens to use
- that makes the binary more portable across older Linux installs

Limitation:

- `cross` helps with building the binary
- it does not prove that the final engine works with Linux desktop GPU, portal, or audio runtime behavior

## 10. GNU vs MUSL For This Project

### 10.1 Summary table

| Topic | `x86_64-unknown-linux-gnu` | `x86_64-unknown-linux-musl` |
|---|---|---|
| Fit for desktop GUI engine | Best default | Experimental |
| Rust support level | Tier 1 | Tier 2 |
| Linux ecosystem fit | Native fit | More friction |
| OpenSSL via `native-tls` | Natural | Extra work |
| Audio / dialogs / desktop libs | Natural | Still not magically static |
| Glibc compatibility drift | Real issue if built on a new distro | Avoided for libc itself |
| Best use in this repo | Main shipping target | Optional experiment |

### 10.2 Why `gnu` should be primary

Use `gnu` first because:

- it matches the normal Linux desktop ABI
- it works naturally with OpenSSL-based `native-tls`
- it is the expected path for GUI desktop applications using GPU, audio, and portal integration
- AppImage and distro packaging workflows are centered around this path

### 10.3 Why `musl` should not be the first target here

`musl` solves only part of the portability problem.

What it helps with:

- static libc
- no glibc version mismatch for libc itself

What it does not solve:

- Vulkan loader and GPU drivers are still external runtime concerns
- XDG portal / desktop integration is still external runtime behavior
- audio behavior is still platform runtime behavior
- `native-tls` on Linux still means OpenSSL concerns unless the dependency setup is changed

Extra complication specific to this repo:

- current HTTP/TLS choice is `ureq` + `native-tls`
- on Linux, `native-tls` uses OpenSSL
- that makes `musl` less clean than it looks unless you also redesign the TLS packaging strategy

### 10.4 Recommendation

Recommendation order:

1. ship `x86_64-unknown-linux-gnu`
2. build it in a controlled old-glibc environment
3. package it as `tar.xz` and optionally AppImage
4. treat `x86_64-unknown-linux-musl` as a later experiment, not the release baseline

## 11. Compression And Size Strategy On Linux

### 11.1 Reality check

Under the full-core assumption, do not plan around a 10 MB raw ELF in the short term.

Plan around three different size layers instead:

- raw executable size
- stripped executable size
- shipped artifact size after packaging compression

For Linux, the user-facing shipped size matters more than the raw ELF size.

### 11.2 What to do first

First size steps that do not cut features:

1. make `profile.dist` truly size-oriented
2. make Linux packaging use `build dist`, not `build release`
3. split debug info out of the shipping binary
4. run `strip --strip-unneeded` as part of the Linux packaging path
5. optionally run UPX on the final ELF if the team accepts the trade-offs
6. always compress the release folder as `tar.xz`
7. optionally add AppImage as a second compressed distribution format

### 11.3 UPX on Linux

Facts:

- UPX supports Linux executables
- it remains the only mainstream executable packer in this space with real adoption
- it is the closest Linux equivalent to the current Windows use of UPX in this repo

Recommendation:

- if the project accepts UPX on Windows, it is technically consistent to also allow it on Linux
- make it optional in the Linux packager: if `upx` exists on PATH, compress; if not, continue with stripped-but-unpacked ELF

### 11.4 Alternatives to UPX

#### A. AppImage compression

This is the recommended alternative.

Why:

- it compresses the shipped Linux artifact rather than mutating the ELF itself
- it is normal in the Linux desktop ecosystem
- it is easier to reason about operationally than shell wrappers or aggressive ELF surgery

What it is not:

- it is not a raw ELF executable compressor
- it is a packaging format with a compressed embedded filesystem and runtime header

Use it when:

- you want easier user distribution and a smaller downloadable artifact
- you do not want to modify the shipped ELF with a packer

#### B. `tar.xz`

This is the minimum recommended packaging compression.

Why:

- safe
- standard
- easy to automate
- no runtime behavior changes

Use it when:

- you want the simplest Linux release artifact now

#### C. `sstrip` from ELFkickers

This is expert-only and not recommended as the default path.

What it does:

- removes a few additional bytes that `strip` leaves behind

Why it is not the default:

- niche tool
- small gains compared to the operational risk
- can make post-build tooling and debugging more annoying

Use it only if:

- size chasing is a deliberate advanced optimization phase
- the team has a regression test for the produced ELF

#### D. `gzexe`

This is rejected as the default shipping method.

What it does:

- replaces the executable with a self-uncompressing shell script wrapper

Why it is a bad default for Lurek2D:

- startup performance penalty
- security caveats
- depends on shell utilities and PATH behavior
- not appropriate as the main delivery format for a desktop game engine

### 11.5 Recommended compression policy

Recommended policy order:

1. `strip --strip-unneeded`
2. split debug info into a sidecar file
3. package folder as `tar.xz`
4. optionally produce AppImage
5. optionally produce UPX-packed ELF as an extra artifact only if team policy allows it

Not recommended as defaults:

- `gzexe`
- `sstrip`
- `musl` as a size shortcut for the whole desktop engine

## 12. Exact Mint And Fedora Playbooks

### 12.1 Linux Mint playbook

Install packages:

```bash
sudo apt update
sudo apt install -y \
  build-essential pkg-config python3 python3-venv git curl \
  libasound2-dev libssl-dev \
  xdg-desktop-portal xdg-desktop-portal-gtk zenity \
  libvulkan1 mesa-vulkan-drivers
```

Install Rust:

```bash
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
rustup default stable
rustup component add rustfmt clippy
```

Build and test:

```bash
python3 tools/dev/parallel_cargo.py build release
python3 tools/dev/parallel_cargo.py test rust
python3 tools/dev/parallel_cargo.py test lua
python3 tools/dev/parallel_cargo.py clippy --deny-warnings
```

Package current artifact:

```bash
bash tools/dist/dist.sh
```

Runtime checks:

- verify `vulkaninfo` works if available
- verify `xdg-desktop-portal` service is running
- verify `zenity --version` works
- run at least one real game/demo, not only tests

### 12.2 Fedora playbook

Install packages:

```bash
sudo dnf install -y \
  gcc gcc-c++ pkgconf-pkg-config python3 git curl \
  alsa-lib-devel openssl-devel \
  xdg-desktop-portal xdg-desktop-portal-gtk zenity \
  vulkan-loader mesa-vulkan-drivers
```

Install Rust:

```bash
curl https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
rustup default stable
rustup component add rustfmt clippy
```

Build and test:

```bash
python3 tools/dev/parallel_cargo.py build release
python3 tools/dev/parallel_cargo.py test rust
python3 tools/dev/parallel_cargo.py test lua
python3 tools/dev/parallel_cargo.py clippy --deny-warnings
```

Package current artifact:

```bash
bash tools/dist/dist.sh
```

Runtime checks:

- if GNOME, keep `xdg-desktop-portal-gtk`
- if KDE, consider `xdg-desktop-portal-kde`
- validate on both Mesa and NVIDIA if Linux is a release target

## 13. Repo Change Plan Under These Assumptions

This plan assumes:

- full core stays full
- plugins are additive only
- no feature cutting to hit size goals

| Phase | Owner | Why it exists | Binary gate |
|---|---|---|---|
| P1 - Define Linux shipping baseline | planner / build-engineer | stop ambiguity between `gnu` and `musl` | written release contract chooses `x86_64-unknown-linux-gnu` as primary |
| P2 - Make `dist` real | build-engineer | today Linux `dist` is not truly distinct from `release` | `cargo build --profile dist` produces a smaller binary than `--release` |
| P3 - Fix Linux packager | build-engineer | `tools/dist/dist.sh` must build `dist`, read `build/dist/lurek2d`, and emit size report | packaging script produces folder + `tar.xz` from `build/dist/lurek2d` |
| P4 - Add Linux compression policy | build-engineer | align Linux with Windows size work without unsafe defaults | Linux packager supports `strip`, optional UPX, and always `tar.xz` |
| P5 - Add optional AppImage path | build-engineer | give a better end-user artifact than raw folder only | AppImage is produced and launch-tested on Linux |
| P6 - Add Linux CI | verifier | repo currently has no real workflow files in this checkout | Ubuntu build + tests + packaging job is green |
| P7 - Merge official docs | doc-writer | convert this research into contributor-facing docs | `docs/handbook.md`, `tools/dist/README.md`, and changelog are updated |

### First recommended phase

Start with P1 + P2 together.

Reason:

- until target and `dist` semantics are explicit, every later packaging discussion is unstable

### Replanning conditions

Replan immediately if any of the following becomes true:

- the project decides that `rustls` should replace `native-tls` on Linux
- the project decides to support AppImage as the main Linux artifact instead of `tar.xz`
- the project decides to revive plugin-based binary reduction despite the current session constraint
- Linux ARM64 becomes a first-class target

## 14. Recommended Official Doc Placement

When this research is merged into product docs, split it like this:

- `docs/handbook.md`: contributor build and test steps for Mint / Fedora
- `tools/dist/README.md`: Linux packaging, `tar.xz`, optional UPX, optional AppImage
- `docs/architecture/philosophy.md`: if the size target is redefined under full-core assumptions
- `docs/CHANGELOG.md`: note that Linux packaging contract was formalized

Do not put all of this into one giant handbook section. Keep contributor workflow separate from packaging policy.

## 15. Final Recommendation

If the goal is "make Linux work reliably now" under the full-core assumption, do this:

1. standardize on `x86_64-unknown-linux-gnu`
2. validate on Mint and Fedora natively
3. make Linux `dist.sh` use `build dist`
4. keep `UPX` optional on Linux
5. use `tar.xz` as the guaranteed compressed artifact
6. add AppImage later as the preferred no-install user artifact
7. keep `musl` experimental until there is a concrete reason to absorb the extra complexity

## 16. Source Set Used

Repo-local sources:

- `Cargo.toml`
- `rust-toolchain.toml`
- `tools/dev/parallel_cargo.py`
- `tools/dist/dist.sh`
- `tools/dist/install.sh`
- `tools/dist/dist.ps1`
- `docs/handbook.md`
- `docs/architecture/philosophy.md`
- `docs/architecture/plugins.md`

Upstream and reference sources consulted:

- Rust target platform support
- rustup cross-compilation guide
- `cross-rs/cross`
- `cpal`
- `rodio`
- `rfd`
- `native-tls`
- `ureq`
- UPX
- `strip(1)`
- `gzexe(1)`
- ELFkickers / `sstrip`
- AppImage documentation
