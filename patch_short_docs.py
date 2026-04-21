import os
import re

files = {
    "src/lua_api/globe_api.rs": [
        ("Create a new globe.", "Creates a new globe instance with default settings and empty collections."),
        ("Returns the globe name.", "Returns the string identifier name assigned to this globe instance."),
        ("Get time of day.", "Gets the current simulated time of day for daylight computation."),
        ("Remove an arc by ID.", "Removes an arc from the globe map by its unique string identifier."),
        ("Remove a label.", "Removes a text label from the globe map by its unique string identifier."),
        ("Remove a layer.", "Removes a texture layer from the globe map by its unique string identifier."),
        ("Remove a marker by ID.", "Removes a marker from the globe map by its unique string identifier."),
        ("Update label text.", "Updates the visible text content of an existing globe label."),
        ("Set label visibility.", "Sets whether this specific label is visible on the globe."),
        ("Set layer visibility.", "Sets whether this specific texture layer is visible on the globe."),
        ("Set marker visibility.", "Sets whether this specific marker is visible on the globe."),
        ("Remove a globe by name.", "Removes a globe from the central registry by its string name."),
    ],
    "src/lua_api/mods_api.rs": [
        ("Returns the display name", "Returns the localized or human-readable display name of the mod.")
    ]
}

for path, replacements in files.items():
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    
    for old, new in replacements:
        text = text.replace(old, new)
        
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"Patched {path}")
