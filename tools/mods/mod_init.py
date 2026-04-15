#!/usr/bin/env python3
"""mod_init.py — Scaffold a minimal Lurek2D mod project.

Usage
-----
    python tools/mods/mod_init.py <mod_name> [--dir <output_dir>] [--author <name>]

Creates:
    <output_dir>/<mod_name>/
        mod.toml       — mod metadata (id, name, version, api_version, capabilities)
        main.lua       — empty entry-point that Lurek2D loads on startup
        README.md      — brief usage stub

Arguments
---------
    mod_name        Identifier for the mod (alphanumeric + underscores).
    --dir           Parent directory for the new mod folder (default: mods/).
    --author        Author name embedded in mod.toml (default: "Unknown").
    --version       Initial mod version string (default: "1.0.0").
    --api            Minimum engine api_version required (default: "0.5").
    --capabilities  Comma-separated capability list (default: none).

Exit codes
----------
    0   Success
    1   Argument error or file-system error
"""

import argparse
import os
import re
import sys
import textwrap


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

_IDENT_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9_]*$")
_SEMVER_RE = re.compile(r"^\d+\.\d+(\.\d+)?$")


def _validate_mod_name(name: str) -> str:
    if not _IDENT_RE.match(name):
        print(
            f"[ERROR] mod_name must start with a letter and contain only "
            f"alphanumerics/underscores; got: {name!r}",
            file=sys.stderr,
        )
        sys.exit(1)
    return name


def _validate_semver(value: str, label: str) -> str:
    if not _SEMVER_RE.match(value):
        print(
            f"[ERROR] {label} must be a semver like '1.0.0' or '0.5'; got: {value!r}",
            file=sys.stderr,
        )
        sys.exit(1)
    return value


# ---------------------------------------------------------------------------
# File templates
# ---------------------------------------------------------------------------

def _mod_toml(mod_id: str, display_name: str, version: str, api_version: str,
              author: str, capabilities: list[str]) -> str:
    cap_str = (
        "\ncapabilities = [" + ", ".join(f'"{c}"' for c in capabilities) + "]"
        if capabilities
        else ""
    )
    return textwrap.dedent(f"""\
        [mod]
        id          = "{mod_id}"
        name        = "{display_name}"
        version     = "{version}"
        api_version = "{api_version}"
        author      = "{author}"
        description = "A Lurek2D mod."{cap_str}
        dependencies = []
    """)


def _main_lua(mod_id: str, display_name: str) -> str:
    return textwrap.dedent(f"""\
        -- {display_name} — main entry point
        -- Lurek2D loads this file when the mod is registered.
        --
        -- Available globals:
        --   lurek   — the engine namespace
        --   MOD     — the ModInfo object for this mod (id, name, version, …)

        lurek.init(function()
            -- Called once after all mods are loaded.
            -- Perform one-time setup here.
        end)

        lurek.ready(function()
            -- Called every time a new game starts.
        end)

        -- Log a startup message so the developer knows the mod loaded.
        if lurek and lurek.log then
            lurek.log.info("[{mod_id}] loaded — version " .. (MOD and MOD:getVersion() or "?"))
        end
    """)


def _readme_md(mod_id: str, display_name: str, author: str, version: str) -> str:
    return textwrap.dedent(f"""\
        # {display_name}

        A Lurek2D mod scaffolded with `tools/mods/mod_init.py`.

        | Field   | Value |
        |---------|-------|
        | ID      | `{mod_id}` |
        | Version | {version} |
        | Author  | {author} |

        ## Installation

        Copy this folder into your game's `mods/` directory and it will be
        loaded automatically by Lurek2D if mod scanning is enabled.

        ## Development

        Edit `main.lua` to add your game logic. See the
        [Lurek2D mod documentation](../../../../docs/specs/mods.md) for
        the full `lurek.modding.*` API reference.
    """)


# ---------------------------------------------------------------------------
# Scaffold
# ---------------------------------------------------------------------------

def scaffold(mod_name: str, parent_dir: str, author: str,
             version: str, api_version: str, capabilities: list[str]) -> None:
    display_name = mod_name.replace("_", " ").title()
    mod_dir = os.path.join(parent_dir, mod_name)

    if os.path.exists(mod_dir):
        print(f"[ERROR] Directory already exists: {mod_dir}", file=sys.stderr)
        sys.exit(1)

    os.makedirs(mod_dir)

    files = {
        "mod.toml": _mod_toml(mod_name, display_name, version, api_version, author, capabilities),
        "main.lua": _main_lua(mod_name, display_name),
        "README.md": _readme_md(mod_name, display_name, author, version),
    }
    for filename, content in files.items():
        path = os.path.join(mod_dir, filename)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
        print(f"  created  {path}")

    print(f"\n[OK] Mod scaffold written to: {os.path.abspath(mod_dir)}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Scaffold a minimal Lurek2D mod project.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("mod_name", help="Mod identifier (letters, digits, underscores).")
    parser.add_argument(
        "--dir", default="mods", metavar="OUTPUT_DIR",
        help="Parent directory for the new mod folder (default: mods/).",
    )
    parser.add_argument("--author", default="Unknown", help="Author name.")
    parser.add_argument("--version", default="1.0.0", help="Initial version (default: 1.0.0).")
    parser.add_argument(
        "--api", default="0.5", metavar="API_VERSION",
        help="Minimum engine api_version required (default: 0.5).",
    )
    parser.add_argument(
        "--capabilities", default="", metavar="CAP1,CAP2",
        help="Comma-separated list of capabilities (e.g. filesystem,network).",
    )
    args = parser.parse_args(argv)

    mod_name = _validate_mod_name(args.mod_name)
    version = _validate_semver(args.version, "--version")
    api_version = _validate_semver(args.api, "--api")
    capabilities = [c.strip() for c in args.capabilities.split(",") if c.strip()]

    scaffold(
        mod_name=mod_name,
        parent_dir=args.dir,
        author=args.author,
        version=version,
        api_version=api_version,
        capabilities=capabilities,
    )


if __name__ == "__main__":
    main()
