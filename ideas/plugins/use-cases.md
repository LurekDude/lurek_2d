# Plugin Architecture — Use Cases

## Game Development (Current Domain)

### Genre-Specific Plugin Packs

Today, every Lurek2D binary includes all Tier 2 modules even if the game doesn't need
them. With plugins, developers load only what they need:

| Genre | Plugins Needed | Plugins NOT Needed |
|-------|---------------|-------------------|
| Arcade | core only | tilemap, ai, pathfinding, gui, terminal |
| RPG | gamedev (full) | terminal |
| Strategy/RTS | tilemap, pathfinding, ai, minimap | spine, terminal |
| Visual Novel | gui, scene | particle, tilemap, physics, ai, terminal |
| Roguelike | tilemap, pathfinding, ai, terminal | spine, minimap |
| Puzzle | core only | tilemap, ai, pathfinding, spine |

**Binary size reduction**: a puzzle game ships `lurek2d.exe` (~15 MB) + no plugin DLLs,
vs. today's ~20 MB monolith. An RPG ships `lurek2d.exe` + `luna_gamedev.dll` (~3 MB).

### Third-Party Game Extensions

With the plugin boundary defined, advanced users can author game-specific plugins:

- **Custom physics** — a 2D soft-body plugin written in Rust, loaded as `luna_softbody.dll`
- **Procedural generation** — specialized terrain/dungeon generators
- **Skeletal animation** — alternative to the built-in spine module
- **Steamworks integration** — `luna_steam.dll` calls the Steam SDK via C FFI
  (kept out of the MIT-licensed core per A-04, but distributable as a separate binary)

---

## Business & Enterprise Applications

### Data Dashboards

Lurek2D's 2D rendering, input handling, and Lua scripting make it viable for interactive
data visualization:

```lua
-- Business dashboard running on Lurek2D
lurek.init(function()
    local df = lurek.dataframe.fromCSV("sales_2024.csv")
    local chart = lurek.dashboard.barChart(df, { x = "month", y = "revenue" })
    chart:setPosition(100, 100)
    chart:setSize(600, 400)
end)

lurek.render(function()
    lurek.render.clear(0.95, 0.95, 0.97)
    chart:draw()
end)
```

**Plugin**: `luna_business.dll` provides `lurek.dataframe`, `lurek.dashboard`,
`lurek.report`, `lurek.workflow`.

### Workflow Automation

Enterprise teams can use Lurek2D + Lua scripting to build internal tools:

- **ETL pipelines** — `lurek.pipeline` for Extract-Transform-Load with visual DAG display
- **Approval workflows** — GUI forms built with `lurek.ui`, state machines via `lurek.ai`
- **Report generation** — read data → process → render to canvas → export PNG/PDF

### Kiosk & Digital Signage

A thin `lurek2d.exe` + `luna_signage.dll` for:
- Menu boards (restaurants, cafeterias)
- Wayfinding displays (airports, hospitals)
- Information kiosks (museums, visitor centers)

Benefits over web-based signage: no browser overhead, direct GPU rendering, runs
offline, starts instantly on boot.

---

## Education

### Interactive Textbooks

Lurek2D can power interactive STEM visualizations:

```lua
-- Physics simulation for an e-textbook
lurek.init(function()
    pendulum = { angle = math.pi/4, omega = 0, length = 200 }
end)

lurek.process(function(dt)
    local g = 9.81
    local alpha = -g / pendulum.length * math.sin(pendulum.angle)
    pendulum.omega = pendulum.omega + alpha * dt
    pendulum.angle = pendulum.angle + pendulum.omega * dt
end)
```

**Plugin**: `luna_education.dll` provides `lurek.simulation`, `lurek.quiz`,
`lurek.annotation` modules.

### Code Learning Environments

Embed Lurek2D in a coding tutor app where students write Lua and see results immediately.
The Lua sandbox ensures student code cannot access the filesystem or crash the host.

### Game Design Courses

Students prototype games using `lurek.*` API. Plugin architecture lets instructors
distribute course-specific modules:
- `luna_course_2024.dll` — assignment framework, auto-grading hooks, asset collections

---

## IoT & Embedded Control Panels

### Sensor Dashboards

For Raspberry Pi or embedded Linux devices with displays:

```lua
-- Industrial sensor display
lurek.init(function()
    lurek.serial.open("COM3", 9600)
end)

lurek.process(function(dt)
    local data = lurek.serial.read("COM3")
    if data then
        temperature = tonumber(data)
    end
end)

lurek.render(function()
    lurek.render.clear(0.1, 0.1, 0.15)
    lurek.render.drawText("Temperature: " .. temperature .. "°C", 100, 100)
    drawGauge(temperature, 0, 100, 400, 300, 150)
end)
```

Benefits: no browser, minimal memory footprint, direct serial port access,
60 FPS rendering on integrated GPUs.

### Machine HMI (Human-Machine Interface)

Replace expensive industrial HMI software with a Lua-scripted alternative:
- `luna_hmi.dll` — `lurek.plc` (PLC communication), `lurek.alarm`, `lurek.trend`
- Configurable via `conf.toml` or SCADA-like definition files
- Runs on standard x86 hardware, not proprietary panels

---

## Simulation & Scientific Visualization

### Agent-Based Modeling

Lurek2D's particle system and entity framework naturally extend to agent-based
simulations:

- **Epidemiology** — disease spread visualization (SIR models)
- **Traffic flow** — road network simulation with pathfinding
- **Ecology** — predator-prey dynamics with spatial rendering

**Plugin**: `luna_simulation.dll` wraps numerical integration, population dynamics,
and spatial hashing.

### 2D CAD / Diagram Editors

With `lurek.render` for rendering, `lurek.input` for interaction, and `lurek.graph` for
data structures, Lurek2D can power:
- Circuit diagram editors
- Flowchart tools
- Level editors for other game engines

---

## Testing & Quality Assurance

### Visual Regression Testing

A headless-capable Lurek2D can render scenes and compare screenshots:

```lua
-- Automated visual regression test
lurek.init(function()
    render_complex_scene()
    lurek.render.saveScreenshot("output/test_scene.png")
    lurek.window.close()
end)
```

Plugins provide test-specific utilities: `luna_testing.dll` with `lurek.compare`,
`lurek.benchmark`, `lurek.fuzz` modules.

### UI Automation

A plugin driving `lurek.automation`:
- Record user interactions
- Replay for regression testing
- Stress test with randomized inputs

---

## Cross-Domain Plugin Opportunities

| Domain | Plugin Name | Key Modules |
|--------|------------|-------------|
| Game Dev | `luna_gamedev` | tilemap, scene, ai, particles, pathfinding, gui |
| Business | `luna_business` | dataframe, pipeline, dashboard, report |
| Education | `luna_education` | simulation, quiz, annotation |
| IoT/HMI | `luna_hmi` | plc, alarm, trend, serial-ext |
| Signage | `luna_signage` | playlist, scheduler, remote-control |
| Simulation | `luna_simulation` | integrator, population, spatial-hash |
| Testing | `luna_testing` | compare, benchmark, fuzz |
| Social/CM | `luna_social` | network-graph, timeline, feed |

Each plugin is a standalone `.dll` / `.so` / `.dylib` that registers into the existing
`lurek.*` namespace. Game scripts and business scripts use the same API patterns.

---

## Licensing & Distribution Model

Plugins enable flexible licensing:

| Component | License | Distribution |
|-----------|---------|-------------|
| `lurek2d-core` + `lurek2d-bin` | MIT (open source) | Free |
| `lurek2d-gamedev` | MIT (open source) | Free |
| `lurek2d-business` | MIT (open source) | Free |
| Third-party plugins | Author's choice | Author distributes |
| `luna_steam.dll` | Proprietary (requires Steam SDK license) | Separate download |

The MIT core + plugin architecture means Lurek2D can power both open-source and
commercial products without license conflicts.
