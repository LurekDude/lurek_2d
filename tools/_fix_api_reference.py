"""
Rewrites wiki/API-Reference.md with four formatting improvements:
 1. Compact inline comments — no padding spaces before '--'
 2. Events as markdown sections outside code blocks (not inside as '-- Events: ...')
 3. Scene transitions as markdown section outside code block
 4. Every module/class heading gets a description sentence (fill gaps)
Return types were already present in most lines; compaction preserves them.
"""
import re, pathlib

WIKI_PATH = pathlib.Path(r"C:\Users\tombl\Documents\luna2d\wiki\API-Reference.md")

COMPACT_COMMENT_RE = re.compile(r'(\S)(\s{2,})(--\s)')

def compact_line(line):
    """Replace 2+ spaces before '-- ' with one space."""
    return COMPACT_COMMENT_RE.sub(r'\1 \3', line)

def compact_code_block(block):
    """Apply compact_line to every line inside a ```lua ... ``` block."""
    return "\n".join(compact_line(l) for l in block.split("\n"))

def transform(text: str) -> str:
    # --- pass 1: compact comments inside code blocks ---
    # Split into code-block and non-code-block segments
    parts = re.split(r'(```lua.*?```)', text, flags=re.DOTALL)
    result_parts = []
    for part in parts:
        if part.startswith("```lua") and part.endswith("```"):
            result_parts.append(compact_code_block(part))
        else:
            result_parts.append(part)
    text = "".join(result_parts)

    # --- pass 2: fix luna.graph events ---
    old_graph_events = (
        '                  g:on(event, fn)\n'
        '-- Events: "itemArrived" "itemDecayed" "itemRejected" "itemCreated" "itemDestroyed"\n'
        '--         "conversionFired" "edgeCooldown" "nodeFull" "nodeEmpty" "supplyMet" "demandUnsatisfied"'
    )
    new_graph_events = '                  g:on(event, fn) -- subscribe to graph events'
    graph_after_block = "\n\n**Events:** `itemArrived` · `itemDecayed` · `itemRejected` · `itemCreated` · `itemDestroyed` · `conversionFired` · `edgeCooldown` · `nodeFull` · `nodeEmpty` · `supplyMet` · `demandUnsatisfied`"

    if old_graph_events in text:
        text = text.replace(old_graph_events, new_graph_events)
        # Insert the markdown events after the closing ``` of the luna.graph code block
        # The graph block ends with the new_graph_events line followed by a ```
        text = text.replace(
            new_graph_events + "\n```\n\n---\n\n## luna.dialog",
            new_graph_events + "\n```" + graph_after_block + "\n\n---\n\n## luna.dialog"
        )

    # --- pass 3: fix luna.dialog events ---
    old_dialog_on = '                  ds:on(event, fn) -- event: "start"|"advance"|"choice"|"end"'
    new_dialog_on = '                  ds:on(event, fn) -- subscribe to sequencer events'
    dialog_after_block = "\n\n**Events:** `start` · `advance` · `choice` · `end`"

    if old_dialog_on in text:
        text = text.replace(old_dialog_on, new_dialog_on)
        # Insert events after the closing ``` of the luna.dialog code block
        text = text.replace(
            new_dialog_on + "\n```\n\n---\n\n## luna.postfx",
            new_dialog_on + "\n```" + dialog_after_block + "\n\n---\n\n## luna.postfx"
        )

    # --- pass 4: luna.scene transitions as markdown ---
    old_transitions = '-- Transitions: "none"  "fade"  "slideLeft"  "slideRight"  "slideUp"  "slideDown"'
    if old_transitions in text:
        # Remove it from inside the code block — find the line and delete it
        text = text.replace("\n" + old_transitions, "")
        # Find end of luna.scene code block and insert there
        # luna.scene block ends with ``` followed by --- and ## luna.entity
        text = text.replace(
            "```\n\n---\n\n## luna.entity",
            "```\n\n**Transitions:** `none` · `fade` · `slideLeft` · `slideRight` · `slideUp` · `slideDown`\n\n---\n\n## luna.entity"
        )

    # --- pass 5: add missing module/class descriptions ---

    # luna.keyboard — add description
    old_kb = "## luna.keyboard\n\n```lua"
    new_kb = "## luna.keyboard\n\nQuery and configure keyboard state.\n\n```lua"
    text = text.replace(old_kb, new_kb)

    # luna.mouse — add description
    old_mouse = "## luna.mouse\n\n```lua"
    new_mouse = "## luna.mouse\n\nQuery pointer position, button state, and cursor visibility.\n\n```lua"
    text = text.replace(old_mouse, new_mouse)

    # luna.gamepad — add description
    old_gp_check = "## luna.gamepad\n\n```lua"
    new_gp_check = "## luna.gamepad\n\nGamepad and joystick state, axis and button queries.\n\n```lua"
    text = text.replace(old_gp_check, new_gp_check)

    # luna.touch — add description
    old_touch = "## luna.touch\n\n```lua"
    new_touch = "## luna.touch\n\nMulti-touch finger tracking (desktop: simulated via mouse).\n\n```lua"
    text = text.replace(old_touch, new_touch)

    # luna.timer — add description
    old_timer = "## luna.timer\n\n```lua"
    new_timer = "## luna.timer\n\nTime queries, delta capping, and delayed/repeating callbacks.\n\n```lua"
    text = text.replace(old_timer, new_timer)

    # luna.event — add description
    old_event = "## luna.event\n\n```lua"
    new_event = "## luna.event\n\nManual event queue: push custom events and poll or listen for them.\n\n```lua"
    text = text.replace(old_event, new_event)

    # luna.system — add description
    old_sys = "## luna.system\n\n```lua"
    new_sys = "## luna.system\n\nOS-level queries: clipboard, open URL, power state, and CPU info.\n\n```lua"
    text = text.replace(old_sys, new_sys)

    # luna.log — add description
    old_log = "## luna.log\n\n```lua"
    new_log = "## luna.log\n\nStructured logging to file and debug overlay at configurable severity levels.\n\n```lua"
    text = text.replace(old_log, new_log)

    # luna.localization — add description
    old_loc = "## luna.localization\n\n```lua"
    new_loc = "## luna.localization\n\nMulti-language string lookup, TOML/JSON locale files, and parametric substitution.\n\n```lua"
    text = text.replace(old_loc, new_loc)

    # luna.debug — add description
    old_dbg = "## luna.debug\n\n```lua"
    new_dbg = "## luna.debug\n\nIn-game overlay, live value watch, and per-frame custom stat graphs.\n\n```lua"
    text = text.replace(old_dbg, new_dbg)

    # Fixtures section — add description
    old_fix = "### Fixtures\n\n```lua"
    new_fix = "### Fixtures\n\nAttach collision shapes (circle or rectangle) to a body to define its physical boundary.\n\n```lua"
    text = text.replace(old_fix, new_fix)

    # Joints section — add description
    old_joints = "### Joints\n\n```lua"
    new_joints = "### Joints\n\nConstraints that link two rigid bodies: revolute (pin), prismatic (slide), and distance.\n\n```lua"
    text = text.replace(old_joints, new_joints)

    return text


if __name__ == "__main__":
    original = WIKI_PATH.read_text(encoding='utf-8')
    transformed = transform(original)
    if transformed == original:
        print("WARNING: No changes were made — check patterns match exactly.")
    else:
        WIKI_PATH.write_text(transformed, encoding='utf-8')
        # Count changed lines
        orig_lines = original.splitlines()
        new_lines = transformed.splitlines()
        changed = sum(1 for a, b in zip(orig_lines, new_lines) if a != b)
        added = len(new_lines) - len(orig_lines)
        print(f"Done. {changed} lines changed, {added:+d} lines net.")
