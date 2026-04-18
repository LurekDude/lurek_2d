"""Self-tests for the CAG validator and audit tools.

Uses ``unittest`` (stdlib) — runnable as::

    python -m unittest tests.python.test_cag_tools

The tests construct synthetic ``.github/`` trees in temporary directories and
exercise each rule and tool.
"""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from textwrap import dedent

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools" / "validate"))
sys.path.insert(0, str(REPO / "tools" / "audit"))


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


# ─── Synthetic CAG layout helpers ────────────────────────────────────────────


VALID_AGENT = dedent("""\
    ---
    name: Developer
    mission: "Implement Rust features for the engine."
    personas: [EngDev, EngTest]
    primary_skills: [rust-coding]
    secondary_skills: []
    routes_to: [Tester]
    loads_tools: [tools/validate/cag_validate.py]
    ---

    # Developer

    ## Mission
    Persona EngDev. Implements Rust.

    ## Scope
    ### Owns
    - src/

    ### Must Not Become
    - Renderer

    ## Inputs
    - issue

    ## Outputs
    - diff

    ## Workflow
    1. Read code.
    2. Edit code.
    3. Run tests.

    ## Routing Table
    | situation | next |
    |---|---|
    | done | Tester |

    ## Anti-patterns
    - git add .
    """)

VALID_SKILL = dedent("""\
    ---
    name: rust-coding
    description: "Load this skill when writing Rust code. Skip it for Lua scripting."
    companion_files:
      examples: []
      templates: []
      snippets: []
    related_skills: []
    ---

    # rust-coding

    ## Mission
    Rust conventions.

    ## When To Load
    - Editing Rust files.

    ## When To Skip
    - Writing Lua.

    ## Domain Knowledge
    Use Result, never unwrap in production paths.

    ## Companion File Index
    No companions yet.

    ## References
    - docs/specs/runtime.md
    """)

VALID_PROMPT = dedent("""\
    ---
    description: "Add a new feature."
    mode: agent
    loads_skills: [rust-coding]
    loads_tools: [tools/validate/cag_validate.py]
    expected_agent: Developer
    inputs_required: [name]
    ---

    # add-feature

    ## Goal
    Implement the named feature.

    ## Inputs
    - name — the feature name.

    ## Steps
    1. Write code.
    2. Run tests.
    3. Commit.

    ## Success Criteria
    - [ ] cargo test passes.

    ## Anti-patterns
    - Skipping tests.

    ## Example Invocation
    Run with name=foo.
    """)

VALID_SYSTEM_PROMPT = dedent("""\
    # Lurek2D — System Prompt

    ## Engine Identity
    Lurek2D is a Rust 2D engine.

    ## Binding Constraints
    - A-01 Runtime only.

    ## Cross-Artifact Sync
    | a | b |
    |---|---|
    | x | y |

    ## Discovery
    Read docs/architecture/cag-system.md for the full reference.

    ## Quality Gates
    cargo test.

    ## Repository Layout
    src/ tools/ docs/
    """)


class _CagFixture:
    """Build an isolated ``.github/`` tree under a temp dir."""

    def __init__(self) -> None:
        self.tmp = tempfile.mkdtemp(prefix="cagtest_")
        self.root = Path(self.tmp)
        self.gh = self.root / ".github"
        (self.gh / "agents").mkdir(parents=True)
        (self.gh / "skills").mkdir(parents=True)
        (self.gh / "prompts").mkdir(parents=True)
        # stub a fake tools/ tree so loads_tools resolves.
        (self.root / "tools" / "validate").mkdir(parents=True)
        (self.root / "tools" / "validate" / "cag_validate.py").write_text("# stub\n",
                                                                          encoding="utf-8")

    def add_skill(self, name: str, body: str = VALID_SKILL) -> Path:
        d = self.gh / "skills" / name
        d.mkdir(parents=True, exist_ok=True)
        f = d / "SKILL.md"
        f.write_text(body, encoding="utf-8")
        return f

    def add_agent(self, filename: str, body: str = VALID_AGENT) -> Path:
        f = self.gh / "agents" / filename
        f.write_text(body, encoding="utf-8")
        return f

    def add_prompt(self, filename: str, body: str = VALID_PROMPT) -> Path:
        f = self.gh / "prompts" / filename
        f.write_text(body, encoding="utf-8")
        return f

    def add_system_prompt(self, body: str = VALID_SYSTEM_PROMPT) -> Path:
        f = self.gh / "copilot-instructions.md"
        f.write_text(body, encoding="utf-8")
        return f


def _patch_cag_to_fixture(fix: _CagFixture, common, validator=None,
                          link_check=None, coverage=None, persona=None):
    """Re-point the loaded modules at a fixture root."""
    common.WORKSPACE_ROOT = fix.root
    common.GITHUB_DIR = fix.gh
    common.SYSTEM_PROMPT = fix.gh / "copilot-instructions.md"
    common.AGENTS_DIR = fix.gh / "agents"
    common.SKILLS_DIR = fix.gh / "skills"
    common.PROMPTS_DIR = fix.gh / "prompts"
    common.TOOLS_DIR = fix.root / "tools"
    for mod in (validator, link_check, coverage, persona):
        if mod is None:
            continue
        for attr in ("WORKSPACE_ROOT", "GITHUB_DIR", "SYSTEM_PROMPT",
                     "AGENTS_DIR", "SKILLS_DIR", "PROMPTS_DIR", "TOOLS_DIR"):
            if hasattr(mod, attr):
                setattr(mod, attr, getattr(common, attr))


# ─── Test cases ───────────────────────────────────────────────────────────────


class CagValidatorRules(unittest.TestCase):
    def setUp(self) -> None:
        self.common = _load("_cag_common",
                            REPO / "tools" / "validate" / "_cag_common.py")
        self.validator = _load("cag_validate",
                               REPO / "tools" / "validate" / "cag_validate.py")
        self.fix = _CagFixture()
        _patch_cag_to_fixture(self.fix, self.common, self.validator)

    def _setup_baseline_valid(self) -> None:
        self.fix.add_skill("rust-coding")
        self.fix.add_agent("developer.agent.md")
        # Stub Tester agent so routes_to: [Tester] resolves.
        self.fix.add_agent(
            "tester.agent.md",
            body=VALID_AGENT.replace("name: Developer", "name: Tester")
                            .replace("routes_to: [Tester]", "routes_to: []"),
        )
        self.fix.add_prompt("add-feature.prompt.md")
        self.fix.add_system_prompt()

    def _rules(self) -> list[str]:
        violations, _ = self.validator.run_validation()
        return [v.rule for v in violations]

    def test_valid_files_have_no_violations(self) -> None:
        self._setup_baseline_valid()
        self.assertEqual(self._rules(), [])

    def test_E001_missing_section(self) -> None:
        self.fix.add_skill("rust-coding")
        self.fix.add_system_prompt(body="# Sys\n\nNo sections here.\n")
        rules = self._rules()
        self.assertIn("E001", rules)

    def test_E002_line_cap(self) -> None:
        body = VALID_SYSTEM_PROMPT + ("\n" * 200)
        self.fix.add_skill("rust-coding")
        self.fix.add_system_prompt(body=body)
        self.assertIn("E002", self._rules())

    def test_E004_inline_roster(self) -> None:
        self.fix.add_skill("rust-coding")
        roster = VALID_SYSTEM_PROMPT + "\n## Agent Roster\n\n- Developer\n"
        self.fix.add_system_prompt(body=roster)
        self.assertIn("E004", self._rules())

    def test_E101_missing_frontmatter(self) -> None:
        self.fix.add_skill("rust-coding")
        self.fix.add_agent("dev.agent.md", body="# No frontmatter\n")
        self.assertIn("E101", self._rules())

    def test_E102_invalid_persona(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_AGENT.replace("[EngDev, EngTest]", "[Wizard]")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("E102", self._rules())

    def test_E103_unknown_skill(self) -> None:
        body = VALID_AGENT.replace("[rust-coding]", "[no-such-skill]")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("E103", self._rules())

    def test_E104_unknown_agent_route(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_AGENT.replace("[Tester]", "[Phantom]")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("E104", self._rules())

    def test_E105_missing_tool(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_AGENT.replace(
            "tools/validate/cag_validate.py", "tools/missing/x.py")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("E105", self._rules())

    def test_E107_missing_section(self) -> None:
        self.fix.add_skill("rust-coding")
        # Drop the Anti-patterns section.
        body = VALID_AGENT.replace("## Anti-patterns\n- git add .\n", "")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("E107", self._rules())

    def test_W108_zero_personas(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_AGENT.replace("[EngDev, EngTest]", "[]")
        self.fix.add_agent("developer.agent.md", body=body)
        self.assertIn("W108", self._rules())

    def test_E201_fenced_block_in_skill(self) -> None:
        body = VALID_SKILL + "\n```rust\nfn main() {}\n```\n"
        self.fix.add_skill("rust-coding", body=body)
        self.assertIn("E201", self._rules())

    def test_E202_skill_no_frontmatter(self) -> None:
        self.fix.add_skill("rust-coding", body="# no frontmatter\n")
        self.assertIn("E202", self._rules())

    def test_E203_missing_companion_file(self) -> None:
        body = VALID_SKILL.replace(
            "companion_files:\n  examples: []",
            "companion_files:\n  examples: [missing.rs]",
        )
        self.fix.add_skill("rust-coding", body=body)
        self.assertIn("E203", self._rules())

    def test_E204_unknown_related_skill(self) -> None:
        body = VALID_SKILL.replace("related_skills: []",
                                   "related_skills: [no-such]")
        self.fix.add_skill("rust-coding", body=body)
        self.assertIn("E204", self._rules())

    def test_E205_missing_skill_section(self) -> None:
        body = VALID_SKILL.replace("## References\n- docs/specs/runtime.md\n", "")
        self.fix.add_skill("rust-coding", body=body)
        self.assertIn("E205", self._rules())

    def test_W206_description_clauses(self) -> None:
        body = VALID_SKILL.replace(
            'description: "Load this skill when writing Rust code. Skip it for Lua scripting."',
            'description: "Just a description without trigger clauses."',
        )
        self.fix.add_skill("rust-coding", body=body)
        self.assertIn("W206", self._rules())

    def test_E301_prompt_no_frontmatter(self) -> None:
        self.fix.add_skill("rust-coding")
        self.fix.add_prompt("p.prompt.md", body="# No frontmatter\n")
        self.assertIn("E301", self._rules())

    def test_E302_unknown_skill_in_prompt(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_PROMPT.replace("[rust-coding]", "[ghost-skill]")
        self.fix.add_prompt("p.prompt.md", body=body)
        self.assertIn("E302", self._rules())

    def test_E303_missing_tool_in_prompt(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_PROMPT.replace(
            "tools/validate/cag_validate.py", "tools/missing/x.py")
        self.fix.add_prompt("p.prompt.md", body=body)
        self.assertIn("E303", self._rules())

    def test_E304_unknown_expected_agent(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_PROMPT.replace("expected_agent: Developer",
                                    "expected_agent: Phantom")
        self.fix.add_prompt("p.prompt.md", body=body)
        self.assertIn("E304", self._rules())

    def test_E305_missing_prompt_section(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_PROMPT.replace("## Anti-patterns\n- Skipping tests.\n", "")
        self.fix.add_prompt("p.prompt.md", body=body)
        self.assertIn("E305", self._rules())

    def test_W306_empty_success_criteria(self) -> None:
        self.fix.add_skill("rust-coding")
        body = VALID_PROMPT.replace("- [ ] cargo test passes.", "_no items_")
        self.fix.add_prompt("p.prompt.md", body=body)
        self.assertIn("W306", self._rules())

    def test_baseline_roundtrip(self) -> None:
        self._setup_baseline_valid()
        # Inject a single error.
        self.fix.add_agent("ghost.agent.md", body="# no frontmatter\n")
        violations, scanned = self.validator.run_validation()
        # Override baseline path to a tempfile for this run.
        bp = Path(self.fix.tmp) / "baseline.json"
        self.validator.BASELINE_PATH = bp
        self.validator.write_baseline(violations, scanned)
        self.assertTrue(bp.exists())
        baseline = self.validator.load_baseline()
        regressions = self.validator.diff_against_baseline(violations, baseline)
        self.assertEqual(regressions, [])


class LinkCheck(unittest.TestCase):
    def test_finds_broken_target(self) -> None:
        common = _load("_cag_common",
                       REPO / "tools" / "validate" / "_cag_common.py")
        link = _load("cag_link_check",
                     REPO / "tools" / "audit" / "cag_link_check.py")
        fix = _CagFixture()
        _patch_cag_to_fixture(fix, common, link_check=link)
        # Add a markdown file with a broken docs/ link.
        (fix.gh / "skills" / "x").mkdir(parents=True)
        (fix.gh / "skills" / "x" / "SKILL.md").write_text(
            "# x\n\nSee [missing](docs/never.md).\n", encoding="utf-8"
        )
        report = link.scan()
        self.assertGreaterEqual(report["broken_total"], 1)
        targets = [b["target"] for b in report["broken"]]
        self.assertIn("docs/never.md", targets)


class Coverage(unittest.TestCase):
    def test_coverage_matrix(self) -> None:
        common = _load("_cag_common",
                       REPO / "tools" / "validate" / "_cag_common.py")
        cov = _load("cag_coverage",
                    REPO / "tools" / "audit" / "cag_coverage.py")
        fix = _CagFixture()
        _patch_cag_to_fixture(fix, common, coverage=cov)
        fix.add_skill("rust-coding")
        report = cov.scan("skill")
        skill = report["skill"]
        self.assertEqual(skill["count"], 1)
        # All required sections should be at 100%.
        for k, v in skill["coverage"].items():
            if k.startswith("sec:"):
                self.assertEqual(v, 100.0, f"{k} should be 100% on the valid skill")


class Personas(unittest.TestCase):
    def test_zero_persona_agent_flagged(self) -> None:
        common = _load("_cag_common",
                       REPO / "tools" / "validate" / "_cag_common.py")
        pm = _load("cag_persona_matrix",
                   REPO / "tools" / "audit" / "cag_persona_matrix.py")
        fix = _CagFixture()
        _patch_cag_to_fixture(fix, common, persona=pm)
        body = VALID_AGENT.replace("[EngDev, EngTest]", "[]")
        fix.add_agent("noperson.agent.md", body=body)
        report = pm.scan()
        self.assertIn("noperson", report["warnings"]["agents_with_zero_personas"])


if __name__ == "__main__":
    unittest.main()
