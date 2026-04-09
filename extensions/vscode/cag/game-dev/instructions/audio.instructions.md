---
applyTo: "**/audio/*.lua"
---
# Audio Module Rules
- Load audio files in luna.load(), never in update/draw
- Use "static" type for short SFX (< 5 seconds)
- Use "stream" type for BGM and long audio
- Always check if source is playing before starting
- Volume values are 0.0 to 1.0
- Use luna.audio for playback control
