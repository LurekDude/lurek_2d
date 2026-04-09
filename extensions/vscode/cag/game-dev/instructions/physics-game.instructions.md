---
applyTo: "**/physics/*.lua"
---
# Physics Module Rules
- Create physics world in lurek.load()
- Step the world in lurek.update(dt), never in draw
- Body types: "static" (walls), "dynamic" (moving), "kinematic" (scripted)
- Use sensors for triggers, not solid bodies
- Physics units are pixels — document scale in comments
- Destroy bodies when entities are removed
- Use collision callbacks for game logic, not overlap tests
