| `item_picked` | item, location | Loot spawn placement |
| `shop_purchase` | item, gold_spent | Economy balance |
| `ability_used` | ability, context | Ability utility |
| `boss_attempt` | boss, attempt_num | Boss difficulty calibration |

### Record for performance analysis

> See [examples/record-for-performance-analysis.lua](examples/record-for-performance-analysis.lua) for the example.

---

### Offline Analysis Workflow
### Death heatmap (Python)

> See [examples/death-heatmap-python.py](examples/death-heatmap-python.py) for the example.

### Level completion funnel (PowerShell)

> See [snippets/level-completion-funnel-powershell.ps1](snippets/level-completion-funnel-powershell.ps1) for the example.

---

### Acting on Findings
| Finding | Typical cause | Design action |
|---------|--------------|---------------|
| Death cluster at one map point | Invisible hazard, unfair spike | Move hazard, add visual cue, reduce damage |
| Level 3 completion rate < 30% | Too hard | Add checkpoint, reduce enemy HP, slow projectiles |
| Ability used < 2% of sessions | Hard to access, not useful | Better UI/hint, buff ability, tutorial |
| Frame spikes every ~60s | GC collect, shader recompile | Move GC to level load, pre-warm shader |
| Crash always after 30+ minutes | Memory leak, accumulating draw state | Profile allocation rate, audit resource release |

---

### Privacy Rule
**Never record personal or identifying information in telemetry.** Lurek2D is a desktop runtime with no network layer. All logs stay on the local machine unless the game explicitly uploads them. Record only gameplay events, positions, and performance data.
