#!/usr/bin/env python3
"""
add_lua_docstrings.py - Auto-generate /// docstrings from inline comments.

This script finds Lua function registrations (lurek.module.function( ... ))
in inline comments and converts them to proper /// docstrings.

Transformations:
  // lurek.graphics.setColor(r, g, b, a?)
  ->
  /// Sets the drawing color for subsequent draw commands.
  ///
  /// Parameters: r, g, b, a (float 0.0-1.0, alpha optional)
  ///
  /// Lua API: lurek.graphics.setColor(r, g, b [, a])
"""

import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_LUA_API_DIR = WORKSPACE_ROOT / "src" / "lua_api"

# Descriptions for common Lua functions (can be extended)
DESCRIPTIONS = {
    # graphics
    "setColor": "Sets the current drawing color for all subsequent draw commands.",
    "setBackgroundColor": "Sets the background (clear) color.",
    "getBackgroundColor": "Returns the current background color.",
    "rectangle": "Draws a rectangle.",
    "circle": "Draws a circle.",
    "ellipse": "Draws an ellipse.",
    "triangle": "Draws a triangle.",
    "polygon": "Draws a polygon.",
    "line": "Draws a line between two points.",
    "draw": "Draws a previously loaded image.",
    "print": "Draws text at the given position.",
    "newImage": "Loads an image file and returns its ID.",
    "clear": "Clears the screen with the current background color.",
    "setLineWidth": "Sets the line width for outline drawing.",
    "getLineWidth": "Returns the current line width.",
    "getWidth": "Returns the window width in pixels.",
    "getHeight": "Returns the window height in pixels.",
    "getDimensions": "Returns the window dimensions (width, height).",
    "getColor": "Returns the current drawing color (r, g, b, a).",
    "push": "Pushes the current transform matrix onto the transform stack.",
    "pop": "Pops the top transform matrix from the stack.",
    "translate": "Translates (moves) the current transform.",
    "rotate": "Rotates the current transform by the given angle in radians.",
    "scale": "Scales the current transform.",
    "arc": "Draws an arc.",
    "newQuad": "Defines a sub-rectangle of a texture (a quad).",
    "drawEx": "Draws an image with a full affine transform.",
    "drawQuad": "Draws a quad region of an image with an affine transform.",
    "polyline": "Draws an open multi-segment polyline.",
    "newFont": "Loads a TTF/OTF font file and returns its ID.",
    "setFont": "Sets the active font for subsequent print calls.",
    "getFont": "Returns the currently active font ID.",
    "getFontWidth": "Returns the width of text in the active font.",
    "getFontHeight": "Returns the height of text in the active font.",

    # audio
    "newSource": "Loads an audio file and returns a source ID.",
    "play": "Plays an audio source from the beginning.",
    "stop": "Stops an audio source.",
    "setVolume": "Sets the volume of an audio source.",
    "getVolume": "Returns the volume of an audio source.",
    "pause": "Pauses an audio source.",
    "resume": "Resumes a paused audio source.",
    "setPitch": "Sets the pitch (playback speed) of an audio source.",
    "isPlaying": "Returns whether an audio source is currently playing.",
    "playLooping": "Plays an audio source in a loop.",

    # filesystem
    "read": "Reads a text file and returns its contents.",
    "write": "Writes a string to a file.",
    "exists": "Checks if a file exists.",

    # input
    "isDown": "Checks if a key or mouse button is currently held down.",
    "getPosition": "Returns the current mouse position.",
    "getX": "Returns the mouse X coordinate.",
    "getY": "Returns the mouse Y coordinate.",

    # physics
    "newWorld": "Creates a physics world with gravity.",
    "newBody": "Creates a rectangular body in a world.",
    "newCircleBody": "Creates a circular body in a world.",
    "setBodySize": "Sets the collision rectangle size of a body.",
    "setBodyShape": "Changes a body's collision shape.",
    "getBodyShape": "Returns the collision shape of a body.",
    "setBodyRestitution": "Sets the bounciness coefficient of a body.",
    "setBodyLayer": "Sets collision layer bitmask filtering for a body.",
    "getBody": "Returns the position and velocity of a body.",
    "setBodyVelocity": "Sets the velocity of a body.",
    "step": "Advances the physics simulation by dt seconds.",
    "getCollisions": "Returns all collision events from the most recent step.",
    "setBodyFriction": "Sets the friction coefficient of a body.",
    "getBodyAngle": "Returns the current rotation of a body.",
    "setBodyAngle": "Sets the rotation of a body.",
    "applyImpulse": "Applies an instantaneous velocity change to a body.",
    "newJoint": "Creates a joint between two bodies.",
    "raycast": "Casts a ray and returns the first body hit.",

    # timer
    "getDelta": "Returns the time (seconds) since the last frame.",
    "getFPS": "Returns the current frames per second.",
    "getTime": "Returns total elapsed time since the game started.",

    # window
    "setTitle": "Sets the window title.",
    "getTitle": "Returns the current window title.",
    "getWidth": "Returns the window width in pixels.",
    "getHeight": "Returns the window height in pixels.",
    "getDimensions": "Returns the window dimensions (width, height).",

    # math
    "sin": "Returns the sine of an angle in radians.",
    "cos": "Returns the cosine of an angle in radians.",
    "tan": "Returns the tangent of an angle in radians.",
    "atan2": "Returns the arctangent of y/x.",
    "sqrt": "Returns the square root.",
    "abs": "Returns the absolute value.",
    "floor": "Returns the floor value.",
    "ceil": "Returns the ceiling value.",
    "min": "Returns the minimum value.",
    "max": "Returns the maximum value.",
    "clamp": "Clamps a value between min and max.",
    "random": "Returns a random number.",
    "distance": "Returns the distance between two points.",
    "normalize": "Normalizes a 2D vector.",
    "lerp": "Performs linear interpolation between two values.",
    "ease": "Applies an easing function.",
    "noise": "Returns 2D Perlin noise.",
    "simplex": "Returns 2D Simplex noise.",
    "fbm": "Returns fractal Brownian motion (layered noise).",

    # particle
    "newSystem": "Creates a particle emitter system.",
    "update": "Advances the particle simulation.",
    "draw": "Queues draw commands for all live particles.",
    "start": "Enables particle emission.",
    "stop": "Disables particle emission.",
    "reset": "Kills all particles and resets the emitter.",
    "getCount": "Returns the number of live particles.",
    "setPosition": "Sets the emitter world-space position.",
    "setEmissionRate": "Changes the emission rate at runtime.",

    # event
    "quit": "Requests engine shutdown.",

    # system
    "getOS": "Returns the operating system name.",
    "getVersion": "Returns the engine version string.",
    "getInfo": "Returns a table with engine information.",
}


def extract_lua_signature(comment: str) -> tuple[str, str, str]:
    """
    Extract module, function name, and signature from a comment.

    Example:
      "lurek.physics.setBodySize(world_id, body_id, w, h)"
      → ("physics", "setBodySize", "(world_id, body_id, w, h)")
    """
    m = re.search(r"luna\.(\w+)\.(\w+)(\([^)]*\))?", comment)
    if m:
        module = m.group(1)
        func_name = m.group(2)
        sig = m.group(3) or ""
        return module, func_name, sig
    return "", "", ""


def add_docstring_to_file(file_path: Path) -> int:
    """
    Add /// docstrings to a Lua API file.

    Returns the number of docstrings added.
    """
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return 0

    lines = content.splitlines(keepends=True)
    result = []
    added = 0
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Detect: // lurek.module.function(...)
        if stripped.startswith("// lurek."):
            module, func_name, sig = extract_lua_signature(stripped)

            # Skip if docstring already exists (next non-empty line is ///)
            has_docstring = i + 1 < len(lines) and "///" in lines[i + 1]
            if not has_docstring:
                desc = DESCRIPTIONS.get(func_name, f"Luna {module} API function.")

                # Add docstring with warning suppression (doc comments on non-items)
                docstring_lines = [
                    f"#[allow(unused_doc_comments)]\n",
                    f"/// {desc}\n",
                    f"/// \n",
                    f"/// Lua API: lurek.{module}.{func_name}{sig}\n",
                ]
                result.extend(docstring_lines)
                added += 1

        result.append(line)
        i += 1

    # Write back if changes were made
    if added > 0:
        try:
            output = "".join(result)
            file_path.write_text(output, encoding="utf-8")
            print(f"[OK] {file_path.name}: Added {added} docstrings")
        except Exception as e:
            print(f"Error writing {file_path}: {e}", file=sys.stderr)
            return 0

    return added


def main():
    # Handle --help flag
    if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        print("\nUsage: python add_lua_docstrings.py")
        print("\nOptions:")
        print("  -h, --help    Show this help message")
        return 0

    total_added = 0

    for rs_file in sorted(SRC_LUA_API_DIR.glob("*_api.rs")):
        added = add_docstring_to_file(rs_file)
        total_added += added

    print(f"\n[OK] Total docstrings added: {total_added}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
