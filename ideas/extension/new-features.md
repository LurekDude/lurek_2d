# New Feature Suggestions

## Features That Don't Exist Yet

### 1. Game Preview Panel

**Concept**: Run the game in an embedded webview panel inside VS Code.

**Why it matters**: Currently developers must switch between VS Code and the game window. An embedded preview eliminates context switching.

**Implementation path**:
- Not feasible with wgpu directly (requires native window)
- Alternative: Capture game framebuffer → stream as images to webview
- Use Debug Bridge screenshot command at 10-30 FPS
- Low fidelity but good for layout/logic debugging
- Higher fidelity: implement a WebGPU render path (long-term, complex)

### 2. Lua REPL / Console Panel

**Concept**: Interactive Lua console connected to the running game.

**Features**:
- Type Lua expressions, see results immediately
- Auto-complete luna.* APIs in the console
- Show print() output in real-time
- Execute multi-line scripts
- History with up/down arrow navigation
- Save console history to file

**Implementation**: Use Debug Bridge's evaluate command + output channel.

### 3. Entity Inspector Panel

**Concept**: Real-time view of all entities in the running game.

**Features**:
- Tree view of all entities with their components
- Click entity → see all properties (position, velocity, health, etc.)
- Edit properties at runtime via Debug Bridge
- Filter/search entities by type or component
- Highlight selected entity in game view
- Entity creation/deletion tracking

### 4. Scene Graph Visualizer

**Concept**: Real-time scene hierarchy visualization.

**Features**:
- Hierarchical view of all active scenes
- Show scene transitions as arrows
- Display scene state (active, loading, paused)
- Click scene → show its entities and callbacks
- Sync with Scene Flow Editor

### 5. Profiler Flame Chart

**Concept**: Visual flame chart for per-function Lua timing.

**Features**:
- Instrument luna.update and luna.draw callbacks
- Show per-function call duration
- Identify hotspots visually
- Compare frames (fast frame vs slow frame)
- Export profile data

**Implementation**: Requires engine-side Lua debug.sethook instrumentation.

### 6. Asset Pipeline Manager

**Concept**: Visual tool for managing game assets end-to-end.

**Features**:
- Import wizard for images, audio, fonts
- Auto-resize images to power-of-two
- Atlas packing (combine sprites into sprite sheets)
- Audio format conversion (WAV → OGG)
- Font subsetting (extract only used characters)
- Asset dependency graph

### 7. Live Style Guide

**Concept**: Auto-generated visual reference of the game's art style.

**Features**:
- Extract all colors used in game code → show palette
- Extract all fonts used → show samples
- Extract all sprites → show gallery
- Extract UI elements → show component library
- Automatically updated as code changes

### 8. Multiplayer Testing Harness

**Concept**: Run multiple game instances with shared state for testing multiplayer.

**Features**:
- Launch N game instances side by side
- Each instance connects via Debug Bridge
- Inject test events (simulate player actions)
- Observe state synchronization
- Record and replay sessions

### 9. Change Impact Analysis

**Concept**: Before saving a Lua file, show what will be affected.

**Features**:
- Parse require() graph to find dependents
- Show list of files that depend on the changed file
- Highlight potentially affected luna.* API calls
- Estimate blast radius of the change
- Suggest relevant tests to run

### 10. Project Templates Gallery

**Concept**: Visual gallery of game templates with live previews.

**Features**:
- Grid of template cards with screenshots
- Categories: Action, RPG, Puzzle, Platformer, Strategy
- One-click scaffold from template
- Template preview (read-only game run)
- Community-submitted templates (future)

**Current state**: scaffold.ts has 3 templates. gameDevCag.ts has 12 templates. These could be unified into a visual gallery.

### 11. Code Playground / Sandbox

**Concept**: Lightweight Lua scratchpad tied to the luna.* API.

**Features**:
- Split view: code on left, output on right
- Auto-run on save (or keystroke with debounce)
- Pre-loaded with luna.* API
- Good for experimenting with API features
- Share snippets as gists

### 12. Game Analytics Dashboard

**Concept**: Collect and visualize game session data from test runs.

**Features**:
- Track events from luna.event.emit() during play sessions
- Show event frequency, timing, and distribution
- Player path visualization (death map, progression funnel)
- Auto-detect difficulty spikes
- Export analytics data for external tools

### 13. Git Integration for Game Assets

**Concept**: Visual diff/merge for game asset files.

**Features**:
- Side-by-side image diff (visual overlay comparison)
- Tilemap diff (highlight changed tiles)
- Audio diff (waveform comparison)
- Entity diff (highlight changed components)
- Better merge conflict resolution for Lua tables

### 14. Accessibility Checker

**Concept**: Automated accessibility analysis of game UI.

**Features**:
- Check color contrast ratios in game palette
- Flag small text sizes
- Check for colorblind-safe palettes
- Suggest audio cues for visual-only feedback
- Check keyboard navigability in menus

### 15. Documentation Generator

**Concept**: Auto-generate game documentation from code.

**Features**:
- Extract luna.load/update/draw structure into a game overview doc
- Document all entities and their components
- Document all scenes and transitions
- Document all input bindings
- Generate API reference for game's custom modules
- Export as Markdown or HTML
