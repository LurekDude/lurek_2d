"""Common helpers shared by CAG validator and audit tools.

Provides:
    * A lightweight YAML frontmatter parser (subset sufficient for CAG files).
    * Link extraction from markdown bodies (markdown links + bare backtick paths).
    * File discovery for the four CAG file types.
    * Repo-root resolution and path normalisation.
    * The closed persona vocabulary and CAG type constants.

No external dependencies; Python 3.11+ stdlib only.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Iterator

# ─── Repo layout ──────────────────────────────────────────────────────────────

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
GITHUB_DIR = WORKSPACE_ROOT / ".github"
SYSTEM_PROMPT = GITHUB_DIR / "copilot-instructions.md"
AGENTS_DIR = GITHUB_DIR / "agents"
SKILLS_DIR = GITHUB_DIR / "skills"
PROMPTS_DIR = GITHUB_DIR / "prompts"
TOOLS_DIR = WORKSPACE_ROOT / "tools"

# ─── CAG types & vocabulary ───────────────────────────────────────────────────

PERSONAS: tuple[str, ...] = (
    "EngDev", "GameDev", "Modder", "Player", "GameTest", "EngTest",
)

CAG_TYPES = ("system_prompt", "agent", "skill", "prompt")

# Required body section headings (markdown ## level), per template.
SYSTEM_PROMPT_REQUIRED_SECTIONS = (
    "Engine Identity",
    "Binding Constraints",
    "Cross-Artifact Sync",
    "Discovery",
    "Quality Gates",
    "Repository Layout",
)
# The pointer to docs/architecture/cag-system.md is required content; checked
# separately as a substring rather than a section heading.
SYSTEM_PROMPT_POINTER = "docs/architecture/cag-system.md"

AGENT_REQUIRED_SECTIONS = (
    "Mission",
    "Scope",
    "Inputs",
    "Outputs",
    "Workflow",
    "Routing Table",
    "Anti-patterns",
)

SKILL_REQUIRED_SECTIONS = (
    "Mission",
    "When To Load",
    "When To Skip",
    "Domain Knowledge",
    "Companion File Index",
    "References",
)

PROMPT_REQUIRED_SECTIONS = (
    "Goal",
    "Inputs",
    "Steps",
    "Success Criteria",
    "Anti-patterns",
    "Example Invocation",
)

# ─── Frontmatter parser ───────────────────────────────────────────────────────

_FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


@dataclass
class Frontmatter:
    """Parsed YAML frontmatter result."""

    present: bool = False
    data: dict[str, object] = field(default_factory=dict)
    raw: str = ""
    error: str | None = None
    body_offset: int = 0  # character offset where body starts

    def get_str(self, key: str, default: str = "") -> str:
        v = self.data.get(key, default)
        return v if isinstance(v, str) else str(v)

    def get_list(self, key: str) -> list[str]:
        v = self.data.get(key)
        if isinstance(v, list):
            return [str(x) for x in v]
        return []

    def get_mapping(self, key: str) -> dict[str, list[str]]:
        v = self.data.get(key)
        if isinstance(v, dict):
            out: dict[str, list[str]] = {}
            for k, val in v.items():
                if isinstance(val, list):
                    out[str(k)] = [str(x) for x in val]
                else:
                    out[str(k)] = [str(val)]
            return out
        return {}


def _strip_quotes(value: str) -> str:
    s = value.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s


def _parse_flow_list(value: str) -> list[str]:
    """Parse a YAML flow-style list `[a, b, "c"]`. Returns [] for `[]`."""
    s = value.strip()
    if not (s.startswith("[") and s.endswith("]")):
        return [s] if s else []
    inner = s[1:-1].strip()
    if not inner:
        return []
    parts: list[str] = []
    cur = ""
    in_quote: str | None = None
    for ch in inner:
        if in_quote:
            cur += ch
            if ch == in_quote:
                in_quote = None
            continue
        if ch in ("'", '"'):
            in_quote = ch
            cur += ch
        elif ch == ",":
            parts.append(_strip_quotes(cur))
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(_strip_quotes(cur))
    return [p for p in (x.strip() for x in parts) if p]


def _parse_yaml_block(text: str) -> dict[str, object]:
    """Parse a YAML subset: scalars, flow lists, and one level of nested map.

    Supports::

        key: value
        key: "quoted"
        key: [a, b]
        key:
          subkey: value
          sublist: [x, y]
    """
    result: dict[str, object] = {}
    lines = text.splitlines()
    i = 0
    n = len(lines)
    while i < n:
        raw = lines[i]
        if not raw.strip() or raw.lstrip().startswith("#"):
            i += 1
            continue
        # Top-level keys have no leading indent.
        if raw[0] in (" ", "\t"):
            i += 1
            continue
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", raw)
        if not m:
            i += 1
            continue
        key, rest = m.group(1), m.group(2).rstrip()
        if rest == "":
            # Could be nested mapping or block list. Look ahead.
            sub: dict[str, object] = {}
            block: list[str] = []
            j = i + 1
            saw_block_list = False
            saw_nested = False
            while j < n:
                nl = lines[j]
                if not nl.strip():
                    j += 1
                    continue
                stripped = nl.lstrip()
                indent = len(nl) - len(stripped)
                if indent == 0:
                    break
                if stripped.startswith("- "):
                    saw_block_list = True
                    block.append(_strip_quotes(stripped[2:].rstrip()))
                else:
                    sm = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", stripped)
                    if sm:
                        saw_nested = True
                        skey, srest = sm.group(1), sm.group(2).rstrip()
                        if srest.startswith("["):
                            sub[skey] = _parse_flow_list(srest)
                        elif srest == "":
                            # Inner block list under this subkey.
                            inner_list: list[str] = []
                            k = j + 1
                            while k < n:
                                il = lines[k]
                                if not il.strip():
                                    k += 1
                                    continue
                                if not il.startswith(" " * (indent + 2)):
                                    break
                                istripped = il.lstrip()
                                if istripped.startswith("- "):
                                    inner_list.append(
                                        _strip_quotes(istripped[2:].rstrip())
                                    )
                                k += 1
                            sub[skey] = inner_list
                            j = k
                            continue
                        else:
                            sub[skey] = _strip_quotes(srest)
                j += 1
            if saw_block_list and not saw_nested:
                result[key] = block
            elif saw_nested:
                result[key] = sub
            else:
                result[key] = ""
            i = j
            continue
        if rest.startswith("["):
            result[key] = _parse_flow_list(rest)
        else:
            result[key] = _strip_quotes(rest)
        i += 1
    return result


def parse_frontmatter(text: str) -> Frontmatter:
    """Parse YAML frontmatter from a markdown file's text."""
    m = _FM_RE.match(text)
    if not m:
        return Frontmatter(present=False)
    raw = m.group(1)
    try:
        data = _parse_yaml_block(raw)
        return Frontmatter(
            present=True, data=data, raw=raw, body_offset=m.end()
        )
    except Exception as exc:  # noqa: BLE001
        return Frontmatter(
            present=False, raw=raw, error=str(exc), body_offset=m.end()
        )


def body_after_frontmatter(text: str, fm: Frontmatter | None = None) -> str:
    """Return the body of a markdown file (everything after the frontmatter)."""
    if fm is None:
        fm = parse_frontmatter(text)
    return text[fm.body_offset:] if fm.present else text


# ─── Link extraction ──────────────────────────────────────────────────────────

_MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
_BACKTICK_PATH_RE = re.compile(
    r"`((?:\.github|tools|docs|src|content|tests|extensions)/[\w./\\-]+)`"
)
_FENCE_RE = re.compile(r"^[ \t]*```", re.MULTILINE)


@dataclass
class LinkRef:
    """A link reference extracted from a markdown body."""

    src: Path                # source file
    target: str              # raw target string (relative or absolute as written)
    line: int                # 1-based line number in source
    kind: str                # "md-link" or "backtick"

    def resolved(self) -> Path | None:
        """Resolve the target relative to the source file's parent."""
        t = self.target.split("#", 1)[0].split("?", 1)[0].strip()
        if not t or t.startswith(("http://", "https://", "mailto:")):
            return None
        if t.startswith(("/", "\\")):
            return None
        # Absolute repo-relative paths
        if t.startswith((".github/", "tools/", "docs/", "src/",
                         "content/", "tests/", "extensions/")):
            return WORKSPACE_ROOT / t
        try:
            return (self.src.parent / t).resolve()
        except OSError:
            return None


def strip_fenced_blocks(text: str) -> str:
    """Replace fenced code blocks with blank lines (preserving line numbers)."""
    out: list[str] = []
    in_fence = False
    for line in text.splitlines():
        if _FENCE_RE.match(line):
            in_fence = not in_fence
            out.append("")
            continue
        out.append("" if in_fence else line)
    return "\n".join(out)


def extract_links(src: Path, text: str, *, skip_fenced: bool = True) -> list[LinkRef]:
    """Extract all markdown links and backtick path-like tokens from text."""
    body = strip_fenced_blocks(text) if skip_fenced else text
    refs: list[LinkRef] = []
    for lineno, line in enumerate(body.splitlines(), start=1):
        for m in _MD_LINK_RE.finditer(line):
            target = m.group(2)
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            refs.append(LinkRef(src=src, target=target, line=lineno, kind="md-link"))
        for m in _BACKTICK_PATH_RE.finditer(line):
            refs.append(LinkRef(src=src, target=m.group(1), line=lineno, kind="backtick"))
    return refs


def find_fenced_block_lines(text: str) -> list[int]:
    """Return 1-based line numbers of every triple-backtick fence marker."""
    return [
        i for i, line in enumerate(text.splitlines(), start=1)
        if _FENCE_RE.match(line)
    ]


# ─── File discovery ───────────────────────────────────────────────────────────


def discover_agents() -> list[Path]:
    if not AGENTS_DIR.exists():
        return []
    return sorted(p for p in AGENTS_DIR.glob("*.agent.md"))


def discover_skills() -> list[Path]:
    if not SKILLS_DIR.exists():
        return []
    out: list[Path] = []
    for d in sorted(SKILLS_DIR.iterdir()):
        if d.is_dir():
            sk = d / "SKILL.md"
            if sk.exists():
                out.append(sk)
    return out


def discover_prompts() -> list[Path]:
    if not PROMPTS_DIR.exists():
        return []
    return sorted(p for p in PROMPTS_DIR.glob("*.prompt.md"))


def discover_all() -> dict[str, list[Path]]:
    out = {
        "system_prompt": [SYSTEM_PROMPT] if SYSTEM_PROMPT.exists() else [],
        "agent": discover_agents(),
        "skill": discover_skills(),
        "prompt": discover_prompts(),
    }
    return out


def known_agent_names() -> set[str]:
    return {p.name.removesuffix(".agent.md") for p in discover_agents()}


def known_skill_names() -> set[str]:
    return {p.parent.name for p in discover_skills()}


def known_prompt_names() -> set[str]:
    return {p.name.removesuffix(".prompt.md") for p in discover_prompts()}


# ─── CAG Metadata body-section parser ────────────────────────────────────────

_CAG_META_LABEL_MAP: dict[str, str] = {
    "personas": "personas",
    "primary skills": "primary_skills",
    "secondary skills": "secondary_skills",
    "routes to": "routes_to",
    "mode": "mode",
    "loads skills": "loads_skills",
    "inputs required": "inputs_required",
    "related skills": "related_skills",
}

_CAG_META_BULLET_RE = re.compile(r"^\s*-\s+\*\*([^*]+)\*\*:\s*(.+)$")

# Keys whose value is always returned as a plain string (not split)
_CAG_META_SCALAR_KEYS = {"mode"}


def parse_cag_metadata_section(text: str) -> dict[str, "str | list[str]"]:
    """Parse the ``## CAG Metadata`` section from file body text.

    Returns a dict mapping canonical key names to either a string scalar
    (for *mode*) or a list of strings (for all other keys). Returns an empty
    dict when the section is absent.

    Supported bullet format::

        - **Personas**: EngDev, GameDev
        - **Primary skills**: rust-coding, error-handling
        - **Routes to**: Lua-Designer, Renderer
        - **Mode**: agent
        - **Loads skills**: visual-effects
        - **Inputs required**: effect_name, target_module
        - **Related skills**: lua-scripting
    """
    result: dict[str, str | list[str]] = {}
    in_cag = False
    for line in text.splitlines():
        heading_m = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if heading_m:
            title = heading_m.group(2).strip().lower()
            if "cag metadata" in title:
                in_cag = True
                continue
            elif in_cag:
                # Any other heading ends the section
                break
            continue
        if not in_cag:
            continue
        bm = _CAG_META_BULLET_RE.match(line)
        if bm:
            label = bm.group(1).strip().lower()
            values_str = bm.group(2).strip()
            key = _CAG_META_LABEL_MAP.get(label)
            if key is None:
                continue
            if key in _CAG_META_SCALAR_KEYS:
                result[key] = values_str
            else:
                result[key] = [v.strip() for v in values_str.split(",") if v.strip()]
    return result


# ─── Section detection ────────────────────────────────────────────────────────

_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")


def find_sections(body: str) -> list[tuple[int, int, str]]:
    """Return list of (line, level, title) for every markdown heading."""
    out: list[tuple[int, int, str]] = []
    for i, line in enumerate(body.splitlines(), start=1):
        m = _HEADING_RE.match(line)
        if m:
            out.append((i, len(m.group(1)), m.group(2).strip()))
    return out


def has_section(body: str, title: str) -> bool:
    """Case-insensitive substring check for a markdown heading title."""
    needle = title.lower()
    for _, _, h in find_sections(body):
        if needle in h.lower():
            return True
    return False


def first_section_line(body: str, title: str) -> int | None:
    needle = title.lower()
    for line, _, h in find_sections(body):
        if needle in h.lower():
            return line
    return None


# ─── Path utilities ───────────────────────────────────────────────────────────


def relpath(p: Path) -> str:
    """Return a forward-slash path relative to the workspace root."""
    try:
        return str(p.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
    except ValueError:
        return str(p).replace("\\", "/")


def safe_read(p: Path) -> str:
    return p.read_text(encoding="utf-8-sig", errors="replace")


# ─── Violation model ──────────────────────────────────────────────────────────


@dataclass
class Violation:
    """A single rule violation."""

    file: str
    rule: str
    severity: str  # "error" or "warning"
    message: str
    line: int = 0

    def to_dict(self) -> dict[str, object]:
        return {
            "file": self.file,
            "line": self.line,
            "rule": self.rule,
            "severity": self.severity,
            "message": self.message,
        }


def violations_to_json(violations: Iterable[Violation]) -> list[dict[str, object]]:
    return [v.to_dict() for v in violations]


def write_json_report(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


__all__ = [
    "WORKSPACE_ROOT", "GITHUB_DIR", "SYSTEM_PROMPT", "AGENTS_DIR",
    "SKILLS_DIR", "PROMPTS_DIR", "TOOLS_DIR",
    "PERSONAS", "CAG_TYPES",
    "SYSTEM_PROMPT_REQUIRED_SECTIONS", "SYSTEM_PROMPT_POINTER",
    "AGENT_REQUIRED_SECTIONS", "SKILL_REQUIRED_SECTIONS",
    "PROMPT_REQUIRED_SECTIONS",
    "Frontmatter", "parse_frontmatter", "body_after_frontmatter",
    "parse_cag_metadata_section",
    "LinkRef", "extract_links", "strip_fenced_blocks", "find_fenced_block_lines",
    "discover_agents", "discover_skills", "discover_prompts", "discover_all",
    "known_agent_names", "known_skill_names", "known_prompt_names",
    "find_sections", "has_section", "first_section_line",
    "relpath", "safe_read",
    "Violation", "violations_to_json", "write_json_report",
]
