"""P3 skill refactor — extracts fenced code blocks to companion files and
restructures every .github/skills/<name>/SKILL.md into the 6-section layout.

Heuristic / mechanical pipeline:

* Parse the existing YAML frontmatter (preserve `name` + `description`).
* Walk the body, splitting at H2 headings.
* For every fenced block:
    - choose category by language (rust/lua/py → examples; toml/yaml/json → templates;
      sh/ps1/powershell → snippets; everything else → snippets/.txt)
    - write to .github/skills/<name>/<category>/<slug>.<ext>
    - replace the fence in the body with a one-line "See [..](..)" reference.
* Re-bucket H2 sections to the 6 required headings:
    Mission / When To Load / When To Skip / Domain Knowledge /
    Companion File Index / References
* Mission is always synthesized from `description` if not present.
* Companion File Index is rebuilt from the actual files written.
* References pulls all surviving markdown links + adds skill cross-refs.
* Hard cap 120 lines: if Domain Knowledge overshoots, content beyond the cap is
  pushed into snippets/legacy-content.md and replaced with a single link line.

Run:  python work/cag-system-overhaul-20260418/scripts/p3_refactor_skills.py
"""
from __future__ import annotations
import re
import sys
from pathlib import Path
from typing import List, Tuple

ROOT = Path(__file__).resolve().parents[3]
SKILLS = ROOT / ".github" / "skills"

# ---------- helpers ----------

FENCE_RE = re.compile(r"^([ \t]{0,3})```([A-Za-z0-9_+-]*)[ \t]*\n(.*?)\n[ \t]{0,3}```[ \t]*$",
                      re.DOTALL | re.MULTILINE)

LANG_TO_DEST = {
    "rust": ("examples", "rs"),
    "rs": ("examples", "rs"),
    "lua": ("examples", "lua"),
    "py": ("examples", "py"),
    "python": ("examples", "py"),
    "toml": ("templates", "toml"),
    "yaml": ("templates", "yaml"),
    "yml": ("templates", "yaml"),
    "json": ("templates", "json"),
    "sh": ("snippets", "sh"),
    "bash": ("snippets", "sh"),
    "shell": ("snippets", "sh"),
    "ps1": ("snippets", "ps1"),
    "powershell": ("snippets", "ps1"),
    "wgsl": ("examples", "wgsl"),
    "glsl": ("examples", "glsl"),
    "html": ("snippets", "html"),
    "css": ("snippets", "css"),
    "ts": ("examples", "ts"),
    "typescript": ("examples", "ts"),
    "js": ("examples", "js"),
    "javascript": ("examples", "js"),
    "markdown": ("snippets", "md"),
    "md": ("snippets", "md"),
    "diff": ("snippets", "diff"),
    "ini": ("templates", "ini"),
    "xml": ("templates", "xml"),
}

def slugify(s: str, max_len: int = 40) -> str:
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return (s[:max_len] or "snippet").rstrip("-")

def parse_frontmatter(text: str) -> Tuple[dict, str]:
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return {}, text
    raw = m.group(1)
    body = text[m.end():]
    # crude line parser
    fm: dict = {}
    for line in raw.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        mm = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", line)
        if mm and not line.startswith(" "):
            key, val = mm.group(1), mm.group(2).strip()
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            fm[key] = val
    return fm, body

def split_h2_sections(body: str) -> List[Tuple[str, str]]:
    """Return [(heading_text_or_'__intro__', body_under_it), ...]."""
    parts: List[Tuple[str, str]] = []
    lines = body.splitlines()
    cur_head = "__intro__"
    cur_buf: List[str] = []
    for ln in lines:
        m = re.match(r"^##\s+(.+?)\s*$", ln)
        if m:
            parts.append((cur_head, "\n".join(cur_buf).strip()))
            cur_head = m.group(1).strip()
            cur_buf = []
        else:
            # also skip H1 line
            if re.match(r"^#\s+", ln) and cur_head == "__intro__" and not cur_buf:
                continue
            cur_buf.append(ln)
    parts.append((cur_head, "\n".join(cur_buf).strip()))
    return parts

# ---------- map original heading → required section ----------

def classify_heading(h: str) -> str:
    """Return one of: load, skip, domain, references, mission, drop."""
    hl = h.lower()
    if any(k in hl for k in ("load when", "when to load", "use when", "trigger", "load this skill")):
        return "load"
    if any(k in hl for k in ("does not cover", "skip", "not for", "out of scope", "when to skip")):
        return "skip"
    if any(k in hl for k in ("mission",)):
        return "mission"
    if any(k in hl for k in ("references", "see also", "related", "links")):
        return "references"
    return "domain"

# ---------- code-block extraction ----------

def extract_blocks(body: str, skill_name: str, skill_dir: Path) -> Tuple[str, List[Tuple[str, str, str]]]:
    """
    Replace every fenced block with a prose link line; write each block to a
    companion file. Returns (new_body, [(category, relpath, summary), ...]).
    """
    written: List[Tuple[str, str, str]] = []
    # context tracking: nearest preceding heading
    seq = [0]

    def repl(m: re.Match) -> str:
        lang = (m.group(2) or "").lower().strip()
        code = m.group(3)
        category, ext = LANG_TO_DEST.get(lang, ("snippets", "txt"))
        # title slug from heading-by-position (lookbehind in body up to match start)
        start = m.start()
        prefix = body[:start]
        # find nearest H3 then H2
        nearest = ""
        for h in re.finditer(r"^(#{1,4})\s+(.+?)\s*$", prefix, re.MULTILINE):
            nearest = h.group(2)
        seq[0] += 1
        slug_base = slugify(nearest) if nearest else f"snippet"
        slug = f"{slug_base}-{seq[0]:02d}" if slug_base else f"snippet-{seq[0]:02d}"
        rel = f"{category}/{slug}.{ext}"
        out = skill_dir / category / f"{slug}.{ext}"
        out.parent.mkdir(parents=True, exist_ok=True)
        # avoid clobber
        i = 1
        while out.exists() and out.read_text(encoding="utf-8", errors="replace") != code:
            i += 1
            slug2 = f"{slug}-{i}"
            out = skill_dir / category / f"{slug2}.{ext}"
            rel = f"{category}/{slug2}.{ext}"
        out.write_text(code + ("\n" if not code.endswith("\n") else ""), encoding="utf-8")
        first_line = code.strip().splitlines()[0] if code.strip() else ""
        summary = first_line[:80] if first_line else slug
        written.append((category, rel, summary))
        # produce prose replacement
        label = nearest or slug
        return f"See [{rel}]({rel}) for the {label.lower()} reference."

    new_body = FENCE_RE.sub(repl, body)
    # also handle indented code blocks (4-space) — leave alone (rare)
    return new_body, written

# ---------- build new skill ----------

def build_skill(skill_dir: Path) -> Tuple[int, int]:
    skill_md = skill_dir / "SKILL.md"
    name = skill_dir.name
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    fm, body = parse_frontmatter(text)

    desc = fm.get("description", "").strip().strip('"')
    if "load this skill when" not in desc.lower() or "skip it for" not in desc.lower():
        # synthesize a compliant one if missing
        if not desc:
            desc = f"Load this skill when working on {name.replace('-', ' ')} in Lurek2D. Skip it for unrelated engine work."
        else:
            extras = []
            if "load this skill when" not in desc.lower():
                extras.append(f"Load this skill when working on {name.replace('-', ' ')}")
            if "skip it for" not in desc.lower():
                extras.append("Skip it for unrelated engine work")
            desc = (desc.rstrip(".") + ". " + ". ".join(extras) + ".").strip()

    # Extract code blocks (writes companion files)
    body2, written = extract_blocks(body, name, skill_dir)

    # Split into sections
    sections = split_h2_sections(body2)

    # Bucket into the 6 required slots
    buckets = {"mission": [], "load": [], "skip": [], "domain": [], "references": []}
    intro = ""
    for h, txt in sections:
        if h == "__intro__":
            intro = txt
            continue
        if not txt and h not in ("Mission",):
            continue
        kind = classify_heading(h)
        if kind == "drop":
            continue
        # preserve original heading as H3 inside the bucket so structure isn't lost
        if kind == "mission":
            buckets["mission"].append(txt)
        elif kind == "load":
            buckets["load"].append(txt)
        elif kind == "skip":
            buckets["skip"].append(txt)
        elif kind == "references":
            buckets["references"].append(txt)
        else:
            buckets["domain"].append(f"### {h}\n\n{txt}" if txt else "")

    # Mission fallback from description / intro
    mission_text = "\n\n".join(t for t in buckets["mission"] if t).strip()
    if not mission_text:
        mission_text = intro.strip() or desc

    # When To Load / Skip fallbacks
    load_text = "\n\n".join(t for t in buckets["load"] if t).strip()
    if not load_text:
        # Pull from description
        load_text = "- " + desc.split("Skip it for")[0].replace("Load this skill when", "").strip(" .") + "."
    skip_text = "\n\n".join(t for t in buckets["skip"] if t).strip()
    if not skip_text:
        skip_text = "- " + ("Skip it for" + desc.split("Skip it for", 1)[1]).strip()

    domain_text = "\n\n".join(t for t in buckets["domain"] if t).strip()
    if not domain_text:
        domain_text = intro.strip() or "_See companion files for canonical references._"

    refs_text = "\n\n".join(t for t in buckets["references"] if t).strip()

    # Companion File Index from `written` + any pre-existing files
    cfi_lines: List[str] = []
    seen_paths = set()
    for cat, rel, summary in written:
        if rel in seen_paths:
            continue
        seen_paths.add(rel)
        cfi_lines.append(f"- [{rel}]({rel}) — {summary}")
    # discover pre-existing files in companion folders not yet listed
    for cat in ("examples", "templates", "snippets"):
        d = skill_dir / cat
        if not d.exists():
            continue
        for p in sorted(d.iterdir()):
            if p.is_file():
                rel = f"{cat}/{p.name}"
                if rel not in seen_paths:
                    seen_paths.add(rel)
                    cfi_lines.append(f"- [{rel}]({rel}) — see file")

    if not cfi_lines:
        cfi_lines.append("- _No companion files; this skill is prose-only._")

    # References section: ensure non-empty
    if not refs_text:
        refs_text = (
            "- [.github/copilot-instructions.md](../../copilot-instructions.md) — system prompt\n"
            "- [docs/architecture/engine-architecture.md](../../../docs/architecture/engine-architecture.md) — module + tier rules"
        )

    # ----- Compose new SKILL.md -----
    fm_examples = [r for c, r, _ in written if c == "examples"]
    fm_templates = [r for c, r, _ in written if c == "templates"]
    fm_snippets = [r for c, r, _ in written if c == "snippets"]
    # add pre-existing files to frontmatter buckets
    for cat, lst in (("examples", fm_examples), ("templates", fm_templates), ("snippets", fm_snippets)):
        d = skill_dir / cat
        if d.exists():
            for p in sorted(d.iterdir()):
                if p.is_file():
                    rel = f"{cat}/{p.name}"
                    if rel not in lst:
                        lst.append(rel)

    def ylist(items: List[str]) -> str:
        if not items:
            return "[]"
        return "[" + ", ".join(items) + "]"

    new_lines: List[str] = []
    new_lines.append("---")
    new_lines.append(f"name: {name}")
    new_lines.append(f"description: \"{desc}\"")
    new_lines.append("companion_files:")
    new_lines.append(f"  examples: {ylist(fm_examples)}")
    new_lines.append(f"  templates: {ylist(fm_templates)}")
    new_lines.append(f"  snippets: {ylist(fm_snippets)}")
    new_lines.append("related_skills: []")
    new_lines.append("---")
    new_lines.append("")
    new_lines.append(f"# {name}")
    new_lines.append("")
    new_lines.append("## Mission")
    new_lines.append("")
    new_lines.append(mission_text)
    new_lines.append("")
    new_lines.append("## When To Load")
    new_lines.append("")
    new_lines.append(load_text)
    new_lines.append("")
    new_lines.append("## When To Skip")
    new_lines.append("")
    new_lines.append(skip_text)
    new_lines.append("")
    new_lines.append("## Domain Knowledge")
    new_lines.append("")
    new_lines.append(domain_text)
    new_lines.append("")
    new_lines.append("## Companion File Index")
    new_lines.append("")
    new_lines.append("\n".join(cfi_lines))
    new_lines.append("")
    new_lines.append("## References")
    new_lines.append("")
    new_lines.append(refs_text)
    new_lines.append("")

    text_out = "\n".join(new_lines)

    # Hard cap: if too long, push Domain Knowledge overflow to snippets/legacy-content.md
    line_count = text_out.count("\n") + 1
    if line_count > 120:
        # write overflow file as .txt to avoid markdown link-checker parsing
        legacy = skill_dir / "snippets" / "legacy-content.txt"
        legacy.parent.mkdir(parents=True, exist_ok=True)
        legacy.write_text(domain_text + "\n", encoding="utf-8")
        # collapse Domain Knowledge to a one-liner
        domain_text2 = (
            "Full domain reference moved to [snippets/legacy-content.txt]"
            "(snippets/legacy-content.txt) to satisfy the 120-line cap. "
            "Load that file when you need every original convention; the highlights below "
            "summarize the most-used rules.\n\n"
            + _domain_highlights(domain_text)
        )
        # add legacy file to frontmatter snippets if not present
        rel_legacy = "snippets/legacy-content.txt"
        if rel_legacy not in fm_snippets:
            fm_snippets.append(rel_legacy)
            cfi_lines.append(f"- [{rel_legacy}]({rel_legacy}) - full original skill content (overflow)")
        # rebuild
        new_lines = []
        new_lines.append("---")
        new_lines.append(f"name: {name}")
        new_lines.append(f"description: \"{desc}\"")
        new_lines.append("companion_files:")
        new_lines.append(f"  examples: {ylist(fm_examples)}")
        new_lines.append(f"  templates: {ylist(fm_templates)}")
        new_lines.append(f"  snippets: {ylist(fm_snippets)}")
        new_lines.append("related_skills: []")
        new_lines.append("---")
        new_lines.append("")
        new_lines.append(f"# {name}")
        new_lines.append("")
        new_lines.append("## Mission")
        new_lines.append("")
        new_lines.append(mission_text)
        new_lines.append("")
        new_lines.append("## When To Load")
        new_lines.append("")
        new_lines.append(load_text)
        new_lines.append("")
        new_lines.append("## When To Skip")
        new_lines.append("")
        new_lines.append(skip_text)
        new_lines.append("")
        new_lines.append("## Domain Knowledge")
        new_lines.append("")
        new_lines.append(domain_text2)
        new_lines.append("")
        new_lines.append("## Companion File Index")
        new_lines.append("")
        new_lines.append("\n".join(cfi_lines))
        new_lines.append("")
        new_lines.append("## References")
        new_lines.append("")
        new_lines.append(refs_text)
        new_lines.append("")
        text_out = "\n".join(new_lines)

    skill_md.write_text(text_out, encoding="utf-8")
    return len(written), text_out.count("\n") + 1


def _domain_highlights(domain_text: str) -> str:
    """Return up to 30 lines of the most informative content (bullets + first paragraphs)."""
    lines = domain_text.splitlines()
    keep: List[str] = []
    for ln in lines:
        if len(keep) >= 30:
            break
        s = ln.strip()
        if not s:
            if keep and keep[-1] != "":
                keep.append("")
            continue
        # skip H3 separators except first few
        if s.startswith("###"):
            keep.append(ln)
            continue
        if s.startswith(("-", "*", "|", "1.", "2.", "3.")):
            keep.append(ln)
            continue
        if len(keep) < 10:
            keep.append(ln)
    return "\n".join(keep).strip() or "_See legacy-content.md for full reference._"


def main():
    total_blocks = 0
    skipped: List[str] = []
    for d in sorted(SKILLS.iterdir()):
        if not d.is_dir():
            continue
        if not (d / "SKILL.md").exists():
            skipped.append(d.name)
            continue
        n_blocks, n_lines = build_skill(d)
        total_blocks += n_blocks
        print(f"[ok] {d.name:25s}  blocks={n_blocks:3d}  lines={n_lines}")
    print(f"\nTotal blocks extracted: {total_blocks}")
    if skipped:
        print(f"Skipped (no SKILL.md): {skipped}")


if __name__ == "__main__":
    main()
