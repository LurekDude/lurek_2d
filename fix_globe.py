"""Quick refactor python script to inject Rust docstrings."""
import os

filename = "src/globe/mod.rs"
with open(filename, "r", encoding="utf-8") as f:
    text = f.read()

replacements = {
    "pub mod draw;": "/// Globe rendering and frame emitting operations.\npub mod draw;",
    "pub mod fog;": "/// Fog of war subsystem for the globe.\npub mod fog;",
    "pub mod label;": "/// Text labels plotted on the globe surface.\npub mod label;",
    "pub mod layer;": "/// Configurable texture overlay boundaries.\npub mod layer;",
    "pub mod lighting;": "/// Real-time shading and day/night terminator computation.\npub mod lighting;",
    "pub mod loader;": "/// Province deserialization from PNGs and TOML files.\npub mod loader;",
    "pub mod marker;": "/// World-space coordinate markers and icons.\npub mod marker;",
    "pub mod picking;": "/// Subsystem to hit-test screen coordinates against provinces.\npub mod picking;",
    "pub mod projection;": "/// 3D spherical rendering pipeline mapping.\npub mod projection;",
    "pub mod registry;": "/// Storage and instantiation of individual globes.\npub mod registry;",
    "pub mod topology;": "/// Mathematical neighborhood graph of connected regions.\npub mod topology;",
    "pub mod types;": "/// Foundational data definitions for the globe.\npub mod types;"
}

for k, v in replacements.items():
    text = text.replace(k, v)

with open(filename, "w", encoding="utf-8") as f:
    f.write(text)
