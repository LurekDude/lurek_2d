# Block Simulator — Visualization Guide

> Reference for visual representation of blocks, ports, edges, states,
> and composite drill-in behavior in the block simulator UI.
> Core system design lives in [BLOCK-DESIGN.md](BLOCK-DESIGN.md).
> Mechanics reference lives in [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md).

---

## Table of Contents

- [1. Block Visual Layout](#1-block-visual-layout)
  - [1.1 Port Positions on Block](#11-port-positions-on-block)
  - [1.2 Port Type Symbols](#12-port-type-symbols)
  - [1.3 Block State Indicators](#13-block-state-indicators)
- [2. Edge Visual Styles](#2-edge-visual-styles)
  - [2.1 Edge Types and Line Styles](#21-edge-types-and-line-styles)
  - [2.2 Edge YAML Examples](#22-edge-yaml-examples)
- [3. Composite Canvas Visualization](#3-composite-canvas-visualization)
  - [3.1 Drill-In Behavior](#31-drill-in-behavior)
  - [3.2 Layer Visualization](#32-layer-visualization)
- [4. Flow Direction Convention](#4-flow-direction-convention)
- [5. Dashboard Visualization Suggestions](#5-dashboard-visualization-suggestions)

---

## 1. Block Visual Layout

### 1.1 Port Positions on Block

```
+------------------------------------------------------------+
|                       BLOCK                                |
|                                                            |
|  LEFT (inputs, top->bottom)   RIGHT (outputs, top->bottom) |
|                                                            |
|  ▲ trigger_in.start             ▼ event_out.done       |
|  ▲ trigger_in.override          ▼ event_out.failed     |
|  ▲ trigger_in.reset   [⬡ SCRIPT]  ⊖ value_cost         |
|  ◇ filter_in.quality            ○ value_out.revenue   |
|  ◇ filter_in.routing            ○ value_out.waste     |
|  □ in: component                □ out: product        |
|  □ in: worker_hours             □ out: rejected       |
|  ⊕ value_in.all                                             |
|                                                            |
+------------------------------------------------------------+
```

Ports are stacked top-to-bottom on each side:

- **LEFT side** (top → bottom): TRIGGER_IN (▲), FILTER_IN (◇), DATA_IN (□), VALUE_IN (⊕)
- **RIGHT side** (top → bottom): EVENT_OUT (▼), VALUE_COST (⊖), VALUE_OUT (○), DATA_OUT (□)
- **CENTER**: SCRIPT (⬡) — internal only, never on an edge

### 1.2 Port Type Symbols

| Symbol | Kind       | Side   | Count     | Notes                              |
| ------ | ---------- | ------ | --------- | ---------------------------------- |
| ▲      | TRIGGER_IN | LEFT   | 0..N      | Named; stacked above filter & data |
| ◇      | FILTER_IN  | LEFT   | 0..N      | Named; stacked below triggers      |
| □      | DATA_IN    | LEFT   | one/type  | Type name = port identity          |
| ⊕      | VALUE_IN   | LEFT   | 0..N      | Aggregates child ⊖ + ○ flows      |
| ▼      | EVENT_OUT  | RIGHT  | 0..N      | Named; stacked above value ports   |
| ⊖      | VALUE_COST | RIGHT  | 0..1      | Running cost per script fire       |
| ○      | VALUE_OUT  | RIGHT  | 0..N      | Named; positive or negative values |
| □      | DATA_OUT   | RIGHT  | one/type  | Type name = port identity          |
| ⬡      | SCRIPT     | CENTER | exactly 1 | Internal only, never on an edge    |

### 1.3 Block State Indicators

Every block has a state machine. State is visible in the UI via block border color:

```
IDLE ──(data arrives / trigger)──▶ WAITING
WAITING ──(requirements met)──────▶ PROCESSING
WAITING ──(timeout)───────────────▶ IDLE  (items stay in container)
PROCESSING ──(step complete)──────▶ PROCESSING (next step)
PROCESSING ──(all steps done)─────▶ IDLE + emit EVENT_OUT + emit VALUE_OUT
PROCESSING ──(step failed)────────▶ FAILED + emit EVENT_OUT(on_fail)
FAILED ──(retry trigger)──────────▶ PROCESSING
FAILED ──(no retry)───────────────▶ IDLE (items discarded or returned)
```

| State      | Border Style         | Meaning                                  |
| ---------- | -------------------- | ---------------------------------------- |
| IDLE       | Gray border          | Block is inactive, waiting for input     |
| WAITING    | Yellow border        | Data arrived, requirements not yet met   |
| PROCESSING | Blue animated border | Script is actively running               |
| FAILED     | Red border           | Last script execution failed             |

---

## 2. Edge Visual Styles

### 2.1 Edge Types and Line Styles

| Edge type    | Line style | Color               | Carries                     |
| ------------ | ---------- | -------------------- | --------------------------- |
| data         | solid      | varies by item type | typed items                 |
| signal       | dashed     | amber               | trigger / event signals     |
| filter       | dashed     | purple              | filter params / gate        |
| value        | dashed     | green               | cost / revenue amounts      |
| backpressure | dashed     | red                 | throttle / pause control    |
| resource     | dotted     | gray                | pool slot claims            |
| compensation | dashed     | orange              | saga rollback instructions  |
| tap          | dotted     | teal                | item copies (non-consuming) |

### 2.2 Edge YAML Examples

```yaml
# Data edge (solid colored line)
- { from: block_a, to: block_b, itemType: component, edge_type: data }

# Signal edge (dashed amber line, triangle ports)
- { from: block_a.event_out, to: block_b.trigger_in, edge_type: signal, signalType: job_done }

# Filter edge (dashed purple line, diamond port)
- { from: param_source, to: block_b.filter_in, edge_type: filter }

# Value edge (dashed green line, circle port)
- { from: block_a.value_out, to: ledger.value_in, edge_type: value }

# Backpressure signal edge (dashed red line — special system edge)
- { from: block_b.backpressure_out, to: block_a.throttle_in, edge_type: backpressure }

# Resource claim edge (dotted gray line — pool membership)
- { from: block_a, to: pool_engineers, edge_type: resource, slots: 2 }

# Compensation edge (dashed orange line — saga rollback path)
- { from: saga_coordinator.rollback_out, to: block_a.compensation_in, edge_type: compensation }

# Tap edge (dotted teal line — non-consuming copy)
- { from: block_a.tap_out, to: analytics_bus, edge_type: tap, sample_rate: 0.1 }
```

---

## 3. Composite Canvas Visualization

### 3.1 Drill-In Behavior

When you **drill into a composite block**, the inner subgraph opens on canvas.
The parent block's ports appear as **boundary port objects** pinned to the canvas walls —
**left wall = inputs, right wall = outputs** — mirroring the block's own left/right model.

```
  LEFT BOUNDARY WALL                               RIGHT BOUNDARY WALL
       |                                                  |
  --> ▲ trigger_in.start  |                              |  ▼ event_out.done   -->
  --> ▲ trigger_in.force  |   +----------------------+   |  ▼ event_out.failed -->
  --> ◇ filter_in.quality |   |  +-----+    +-----+  |   |  ⊖ value_cost       -->
  --> ◇ filter_in.routing |   |  |  A  |--->|  B  |  |   |  ○ value_out.rev    -->
  --> □ in:order          |   |  +-----+    +-----+  |   |  □ out:product      -->
  --> □ in:component      |   +----------------------+   |  □ out:rejected     -->
       |                                                  |
```

Inner blocks connect their **output ports** (right side) to the right boundary wall, which
carries data to the next block in the parent graph.
Inner blocks receive their **input ports** (left side) from the left boundary wall, which
accepts data arriving from the upstream block in the parent graph.

The boundary wall objects ARE the composite block's ports — just rendered as pinned
markers inside the drilled canvas.

### 3.2 Layer Visualization

Composite blocks nest freely. There is no depth limit. Drilling into each layer reveals the next level of detail.

| Layer | Contains              | Typical real-world unit                   |
|-------|-----------------------|-------------------------------------------|
| L0    | Atomic (SCRIPT ⬡)  | programmer, machine, API call, check       |
| L1    | Group of L0 atomics   | team, production cell, microservice       |
| L2    | Group of L1 composites| department, factory floor, platform       |
| L3    | Group of L2 composites| business unit, site, product line         |
| L4+   | Group of L(N-1)       | company, enterprise, value stream         |

**Queue depth is visible at every level.** Drilling into a composite shows live queue depths
for every inner block. The composite itself has **no queue of its own** — its boundary walls
are transparent wires.

```
 Parent graph item arrives at composite LEFT wall
         |
         v    (no buffering at composite boundary — it is a direct wire)
 [Atomic A: container = 0/50 items]
         |
  SCRIPT fires when conditions met
         |
         v
 [Atomic B: container = 3/50 items   <-- bottleneck visible here]
         |
  SCRIPT fires
         |
         v
 Parent graph item exits at composite RIGHT wall
```

Value flows are also visible through layers:

```
 [coder]    ⊖ cost:50  ───────┐
 [reviewer] ⊖ cost:30  ───────┤
 [tester]   ⊖ cost:40  ───────┤──> dev_team ⊕VALUE_IN ──> aggregate ──> ⊖ cost:120
                                   │                                             ○ value:200
 [coder]    ○ value:200 ──────┘
```

---

## 4. Flow Direction Convention

- **Items flow left → right.** An edge always runs from a RIGHT-side port of one block to a LEFT-side port of another.
- **Inputs always on LEFT wall** of any block or composite boundary.
- **Outputs always on RIGHT wall** of any block or composite boundary.
- Port shape signals port kind at a glance — see [§1.2 Port Type Symbols](#12-port-type-symbols).
- **No DATA_OUT on left; no DATA_IN on right.** Direction is absolute.

For full port definitions and YAML syntax, see [BLOCK-DESIGN.md §2 — Port Types](BLOCK-DESIGN.md).

---

## 5. Dashboard Visualization Suggestions

Practical suggestions for rendering the block simulator in a web dashboard UI.

### 5.1 Block Canvas Layout

- Render blocks as rectangular cards on a 2D canvas with left-to-right flow.
- Use a horizontal dagre or ELK layout algorithm to auto-position blocks following the flow direction.
- Composite blocks render as larger cards with a "drill-in" affordance (double-click or expand icon).
- Blocks should be draggable for manual arrangement, with snap-to-grid for alignment.

### 5.2 Port Rendering

- Render ports as small icons using their defined symbols (▲ ◇ □ ⊕ ▼ ⊖ ○ ⬡).
- Left-side ports attach to the left edge of the block card; right-side ports to the right edge.
- Stack ports top-to-bottom in the defined order: triggers → filters → data → value.
- Show port name as a tooltip on hover; optionally as a small label beside the port icon.

### 5.3 Edge Rendering

- Use the edge visual styles from [§2.1](#21-edge-types-and-line-styles) directly:
  - **Data edges**: solid lines, color-coded per item type.
  - **Signal edges**: dashed amber lines with arrowheads.
  - **Filter edges**: dashed purple lines.
  - **Value edges**: dashed green lines.
  - **Backpressure edges**: dashed red lines — highlight these prominently when active.
  - **Tap edges**: dotted teal lines — render with lower opacity to indicate non-consuming observation.
- Animate edges during active item transfer (particle dots moving along the line).

### 5.4 State Visualization

Use block border colors from [§1.3](#13-block-state-indicators):

| Visual treatment          | State       | Effect                                     |
| ------------------------- | ----------- | ------------------------------------------ |
| Gray border (default)     | IDLE        | No animation                               |
| Yellow border             | WAITING     | Subtle pulse to indicate pending            |
| Blue animated border      | PROCESSING  | Rotating dash or glow animation             |
| Red border                | FAILED      | Solid red, optional shake on transition     |

### 5.5 Queue Depth Color Coding

Visualize container fill ratio with a progress bar inside the block card:

| Fill ratio    | Color  | Meaning                        |
| ------------- | ------ | ------------------------------ |
| 0–50%         | Green  | Healthy capacity               |
| 50–80%        | Yellow | Approaching capacity           |
| 80–95%        | Orange | Near full, backpressure likely |
| 95–100%       | Red    | At capacity, items may be rejected |

Show the numeric count (e.g., `23/50`) alongside the bar.

### 5.6 Item Flow Particle Trails

- Animate small dots or particles along edges when items move between blocks.
- Particle color should match the edge type color (e.g., amber dots on signal edges).
- Particle speed should correspond to processing speed — faster particles for higher throughput.
- Accumulate particles at block boundaries when queues are filling up.

### 5.7 Live State Pulsing

- PROCESSING blocks should have a smooth blue glow or border animation.
- Freshly transitioned blocks (e.g., IDLE → PROCESSING) should briefly flash to draw attention.
- FAILED blocks should flash red once on transition, then hold solid red.

### 5.8 Anomaly Visual Indicators

- Display a ⚠ warning triangle icon on blocks that have triggered anomaly detection thresholds.
- Color-code anomaly severity: yellow for warnings, red for critical anomalies.
- Show anomaly details in a tooltip or side panel on click.
- Highlight the affected edge in red if the anomaly relates to flow (e.g., throughput drop).

### 5.9 Monitor Attachment Indicators

- Display a 👁 eye icon on blocks that have an attached monitor or tap edge.
- Clicking the eye icon should show the monitor's current readings (throughput, latency, error rate).
- Tap edges (dotted teal) should visually connect to a monitor panel or analytics bus block.

### 5.10 Heat Map Overlays

Toggle-able overlays that color blocks by operational metrics:

| Overlay mode  | Color scale          | Metric                      |
| ------------- | -------------------- | --------------------------- |
| Throughput    | Blue → Red           | Items processed per tick    |
| Utilization   | Green → Red          | Processing time / available time |
| Queue depth   | Green → Red          | Current fill / max capacity |
| Cost          | Light gold → Dark gold | Accumulated VALUE_COST (⊖)  |
| Error rate    | Green → Red          | Failed / total items        |

Heat map mode should be selectable from a toolbar dropdown. Each overlay replaces the block's
background color with the gradient value.

### 5.11 Composite Drill-In UX

- Double-click a composite block to drill in; show a breadcrumb trail (e.g., `Company > Dept > Team`).
- Render boundary walls as vertical bars on the left and right edges of the drill-in canvas.
- Pin boundary port objects (▲ ◇ □ etc.) to the walls exactly as shown in [§3.1](#31-drill-in-behavior).
- Provide a "zoom out" button or breadcrumb click to return to the parent layer.
- Show a minimap of the parent graph in the corner, highlighting the current composite's position.
